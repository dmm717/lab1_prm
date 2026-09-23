import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/keyword_model.dart';
import '../models/paper_model.dart';
import '../services/backend_service.dart';
import '../services/paper_storage_service.dart';

enum IngestionStage {
  idle,
  downloadingPdf,
  parsingGrobid,
  analyzingTei,
  synthesizingGemini,
  completed,
  error,
}

class PaperController extends ChangeNotifier {
  late BackendService _backendService;
  final PaperStorageService _storageService = PaperStorageService();

  bool _isGrobidAlive = false;
  IngestionStage _stage = IngestionStage.idle;
  String _statusMessage = '';
  double _progress = 0.0;
  String? _errorMessage;

  PaperModel? _currentPaper;
  Uint8List? _currentPdfBytes;
  bool _isFetchingDoi = false;
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;

  List<PaperModel> _recentPapers = [];

  // Getters
  bool get isGrobidAlive => _isGrobidAlive;
  IngestionStage get stage => _stage;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  int get progressPercentage => (_progress * 100).clamp(0, 100).toInt();
  String? get errorMessage => _errorMessage;
  PaperModel? get currentPaper => _currentPaper;
  Uint8List? get currentPdfBytes => _currentPdfBytes;
  bool get isFetchingDoi => _isFetchingDoi;
  List<ChatMessage> get messages => UnmodifiableListView(_messages);
  bool get isStreaming => _isStreaming;
  bool get hasPaper => _currentPaper != null;
  bool get isFallbackMode => _currentPaper?.isFallback ?? false;
  List<PaperModel> get recentPapers => UnmodifiableListView(_recentPapers);

  PaperController() {
    _backendService = BackendService();
    _initialize();
  }

  Future<void> _initialize() async {
    // Remove credentials and settings saved by older desktop builds.
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('gemini_api_key');
    await preferences.remove('selected_gemini_model');
    await preferences.remove('grobid_base_url');
    await loadRecentPapers();
    notifyListeners();
    await checkGrobidHealth();
  }

  Future<void> loadRecentPapers() async {
    _recentPapers = await _storageService.getRecentPapers();
    notifyListeners();
  }

  Future<bool> checkGrobidHealth() async {
    _isGrobidAlive = await _backendService.checkGrobidHealth();
    notifyListeners();
    return _isGrobidAlive;
  }

  Future<void> processLocalPdf(
    Uint8List pdfBytes,
    String filename, {
    String? localPdfPath,
  }) async {
    if (_stage != IngestionStage.idle &&
        _stage != IngestionStage.completed &&
        _stage != IngestionStage.error) {
      return;
    }
    _errorMessage = null;

    if (pdfBytes.length < 5 ||
        pdfBytes[0] != 0x25 ||
        pdfBytes[1] != 0x50 ||
        pdfBytes[2] != 0x44 ||
        pdfBytes[3] != 0x46 ||
        pdfBytes[4] != 0x2D) {
      _stage = IngestionStage.error;
      _errorMessage = 'Tệp được chọn không phải PDF hợp lệ.';
      notifyListeners();
      return;
    }

    try {
      final cleanId =
          filename.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
      _stage = IngestionStage.parsingGrobid;
      _statusMessage = 'Đang gửi $filename đến GROBID...';
      _progress = 0.20;
      notifyListeners();

      final paper = await _backendService.processFulltextDocument(
        pdfBytes,
        filename: filename,
        sourceId: cleanId,
        sourceUrl: 'local://$filename',
        onSendProgress: (sent, total) {
          if (total > 0) {
            final percent = sent / total;
            _progress = 0.20 + percent * 0.50;
            final mbSent = (sent / (1024 * 1024)).toStringAsFixed(1);
            final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
            _statusMessage = percent >= 1
                ? 'GROBID đang trích xuất nội dung PDF...'
                : 'Đang gửi PDF: $mbSent MB / $mbTotal MB';
            notifyListeners();
          }
        },
      );

      paper.localPdfPath = localPdfPath;
      _currentPdfBytes = pdfBytes;

      _statusMessage = 'Đã trích xuất nội dung bài báo.';
      _progress = 0.90;
      notifyListeners();

      _currentPaper = paper;
      _stage = IngestionStage.completed;
      _statusMessage = 'Đã trích xuất PDF bằng GROBID.';
      _progress = 1.0;

      // Persist paper to offline local storage (Task F1)
      await _storageService.savePaper(paper);
      await loadRecentPapers();

      // Check for saved chat history or create default greeting (Task F2)
      final savedMessages = await _storageService.getChatHistory(paper.id);
      _messages.clear();

      if (savedMessages.isNotEmpty) {
        _messages.addAll(savedMessages);
      } else {
        final imgrad = paper.effectiveImgrad;
        _messages.add(
          ChatMessage.assistant(
            'Đã trích xuất bài báo **"${paper.title}"** bằng GROBID.\n\n'
            '📘 **[I - Introduction / Đặt Vấn Đề & Mục Tiêu]**\n'
            '${imgrad.introduction.summary}\n\n'
            '⚙️ **[M - Methodology / Phương Pháp Luận & Mô Hình]**\n'
            '${imgrad.methodology.summary}\n\n'
            '📊 **[R - Results / Kết Quả & Số Liệu Thực Nghiệm]**\n'
            '${imgrad.results.summary}\n\n'
            '💡 **[D - Discussion / Thảo Luận, Hạn Chế & Kết Luận]**\n'
            '${imgrad.discussion.summary}\n\n'
            '---\n'
            '💡 *Bạn có thể bấm vào các gợi ý bên dưới hoặc hỏi bất kỳ chi tiết nào về từng phần IMGRaD.*',
          ),
        );
        await _storageService.saveChatHistory(paper.id, _messages);
      }

      notifyListeners();
    } catch (e) {
      _stage = IngestionStage.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void closeCurrentPaper() {
    _currentPaper = null;
    _currentPdfBytes = null;
    _messages.clear();
    _stage = IngestionStage.idle;
    _statusMessage = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Triggers DOI Fetch tool to look up paper metadata via CrossRef API
  Future<bool> fetchDoiForCurrentPaper() async {
    if (_currentPaper == null || _isFetchingDoi) return false;

    _isFetchingDoi = true;
    notifyListeners();

    try {
      final res = await _backendService.fetchDoiMetadata(
        title: _currentPaper!.title,
        doi: _currentPaper!.doi,
      );

      if (res != null) {
        if (res['doi'] != null) _currentPaper!.doi = res['doi'].toString();
        if (res['issn'] != null) _currentPaper!.issn = res['issn'].toString();
        if (res['isbn'] != null) _currentPaper!.isbn = res['isbn'].toString();
        if (res['arxivId'] != null)
          _currentPaper!.arxivId = res['arxivId'].toString();
        if (res['journal'] != null)
          _currentPaper!.journal = res['journal'].toString();
        if (res['publisher'] != null)
          _currentPaper!.publisher = res['publisher'].toString();
        if (res['volume'] != null)
          _currentPaper!.volume = res['volume'].toString();
        if (res['issue'] != null)
          _currentPaper!.issue = res['issue'].toString();
        if (res['pages'] != null)
          _currentPaper!.pages = res['pages'].toString();
        if (res['citationCount'] is int)
          _currentPaper!.citationCount = res['citationCount'] as int;
        if (res['publicationDate'] != null) {
          _currentPaper!.publicationDate = res['publicationDate'].toString();
        }

        await _storageService.savePaper(_currentPaper!);
        await loadRecentPapers();
        notifyListeners();
        return true;
      }
    } catch (_) {
    } finally {
      _isFetchingDoi = false;
      notifyListeners();
    }
    return false;
  }

  /// Selects a paper from local storage without re-downloading or re-uploading (Task F1)
  Future<void> selectRecentPaper(PaperModel paper) async {
    _currentPaper = paper;
    _currentPdfBytes = null;
    _errorMessage = null;
    _stage = IngestionStage.completed;
    _statusMessage = 'Đã mở "${paper.title}" từ bộ nhớ máy.';

    // Load persisted chat history for this paper (Task F2)
    final savedMessages = await _storageService.getChatHistory(paper.id);
    _messages.clear();

    if (savedMessages.isNotEmpty) {
      _messages.addAll(savedMessages);
    } else {
      _messages.add(
        ChatMessage.assistant(
          'Tôi đã mở bài báo **"${paper.title}"** từ thư viện đã lưu của bạn.\n\n'
          'Bạn muốn tìm hiểu hoặc thảo luận điều gì về bài báo này?',
        ),
      );
      await _storageService.saveChatHistory(paper.id, _messages);
    }

    notifyListeners();
  }

  /// Deletes a paper from local storage
  Future<void> deleteRecentPaper(String paperId) async {
    await _storageService.deletePaper(paperId);
    if (_currentPaper?.id == paperId) {
      _currentPaper = null;
      _currentPdfBytes = null;
      _messages.clear();
      _stage = IngestionStage.idle;
      _statusMessage = '';
    }
    await loadRecentPapers();
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _currentPaper == null || _isStreaming) return;

    final paper = _currentPaper!;
    final priorHistory = List<ChatMessage>.from(_messages);
    final userMsg = ChatMessage.user(cleanText);
    final assistantMsg = ChatMessage.streaming();

    _messages.add(userMsg);
    _messages.add(assistantMsg);
    _isStreaming = true;
    notifyListeners();

    try {
      final stream = _backendService.streamPaperChat(
        paper: paper,
        history: priorHistory,
        userMessage: cleanText,
      );

      await for (final chunk in stream) {
        if (_currentPaper?.id != paper.id) break;
        assistantMsg.content += chunk;
        notifyListeners();
      }

      assistantMsg.isStreaming = false;
      // Persist updated chat conversation (Task F2)
      if (_currentPaper?.id == paper.id) {
        await _storageService.saveChatHistory(paper.id, _messages);
      }
    } catch (e) {
      assistantMsg.isStreaming = false;
      assistantMsg.isError = true;
      assistantMsg.content =
          'Lỗi trong quá trình phản hồi: ${e.toString().replaceAll('Exception: ', '')}';
      if (_currentPaper?.id == paper.id) {
        await _storageService.saveChatHistory(paper.id, _messages);
      }
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  void askAboutKeyword(KeywordModel keyword) {
    sendMessage(
      'Hãy giải thích chi tiết về khái niệm **"${keyword.term}"** trong bài báo này. '
      'Các tác giả triển khai hoặc áp dụng nó như thế nào và vai trò của nó trong toàn bộ phương pháp nghiên cứu là gì?',
    );
  }

  void clearChat() async {
    if (_isStreaming) return;
    _messages.clear();
    if (_currentPaper != null) {
      _messages.add(
        ChatMessage.assistant(
            'Cuộc trò chuyện đã được đặt lại. Bạn muốn tìm hiểu thêm điều gì về "${_currentPaper!.title}"?'),
      );
      await _storageService.saveChatHistory(_currentPaper!.id, _messages);
    }
    notifyListeners();
  }

  /// Exports current chat history as Markdown
  String exportChatAsMarkdown() {
    if (_currentPaper == null) return '';
    final buffer = StringBuffer();
    buffer.writeln('# Lịch Sử Hội Thoại: ${_currentPaper!.title}');
    buffer.writeln('**Thời gian xuất**: ${DateTime.now().toIso8601String()}\n');
    buffer.writeln('---\n');

    for (final msg in _messages) {
      final role = msg.role == MessageRole.user
          ? '### 👤 Người Dùng'
          : '### 🤖 Trợ Lý PaperChat AI';
      buffer.writeln('$role\n');
      buffer.writeln('${msg.content}\n');
    }

    return buffer.toString();
  }
}
