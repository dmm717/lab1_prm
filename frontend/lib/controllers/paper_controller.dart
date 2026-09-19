import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/keyword_model.dart';
import '../models/paper_model.dart';
import '../services/arxiv_service.dart';
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

  String _geminiApiKey = AppConstants.defaultGeminiApiKey;
  String _selectedModel = AppConstants.defaultGeminiModel;
  String _backendUrl = 'http://localhost:8080';

  bool _isGrobidAlive = false;
  IngestionStage _stage = IngestionStage.idle;
  String _statusMessage = '';
  double _progress = 0.0;
  String? _errorMessage;

  PaperModel? _currentPaper;
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;

  List<PaperModel> _recentPapers = [];

  // Getters
  String get grobidUrl => _backendUrl; // alias for compatibility with UI
  String get geminiApiKey => _geminiApiKey;
  String get selectedModel => _selectedModel;
  bool get isGrobidAlive => _isGrobidAlive;
  IngestionStage get stage => _stage;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  int get progressPercentage => (_progress * 100).clamp(0, 100).toInt();
  String? get errorMessage => _errorMessage;
  PaperModel? get currentPaper => _currentPaper;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  bool get hasPaper => _currentPaper != null;
  bool get isFallbackMode => _currentPaper?.isFallback ?? false;
  List<PaperModel> get recentPapers => List.unmodifiable(_recentPapers);

  PaperController() {
    _backendService = BackendService(backendUrl: _backendUrl);
    initSettings();
  }

  Future<void> initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString(AppConstants.keyGeminiApiKey) ?? '';
    _geminiApiKey = savedKey.isNotEmpty ? savedKey : AppConstants.defaultGeminiApiKey;
    _backendUrl = prefs.getString(AppConstants.keyGrobidBaseUrl) ?? 'http://localhost:8080';
    _selectedModel = prefs.getString(AppConstants.keySelectedModel) ?? AppConstants.defaultGeminiModel;

    _backendService = BackendService(backendUrl: _backendUrl);

    await loadRecentPapers();
    notifyListeners();
    await checkGrobidHealth();
  }

  Future<void> loadRecentPapers() async {
    _recentPapers = await _storageService.getRecentPapers();
    notifyListeners();
  }

  Future<void> updateSettings({
    required String apiKey,
    required String grobidUrl,
    required String model,
  }) async {
    _geminiApiKey = apiKey.trim();
    _backendUrl = grobidUrl.trim();
    _selectedModel = model;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyGeminiApiKey, _geminiApiKey);
    await prefs.setString(AppConstants.keyGrobidBaseUrl, _backendUrl);
    await prefs.setString(AppConstants.keySelectedModel, _selectedModel);

    _backendService = BackendService(backendUrl: _backendUrl);

    notifyListeners();
    await checkGrobidHealth();
  }

  Future<bool> checkGrobidHealth() async {
    _isGrobidAlive = await _backendService.checkIsAlive();
    notifyListeners();
    return _isGrobidAlive;
  }

  Future<void> processInputUrl(String inputUrl) async {
    _errorMessage = null;
    final cleanUrl = inputUrl.trim();
    if (cleanUrl.isEmpty) return;

    final isWebUrl = cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://');
    final arxivId = ArxivService.extractArxivId(cleanUrl);

    if (!isWebUrl && arxivId == null) {
      _errorMessage = 'Đường dẫn không hợp lệ. Vui lòng nhập liên kết bài báo (VnExpress, báo chí, hoặc ArXiv).';
      notifyListeners();
      return;
    }

    try {
      _stage = IngestionStage.downloadingPdf;
      _statusMessage = 'Đang kết nối tới liên kết bài báo...';
      _progress = 0.15;
      notifyListeners();

      PaperModel paper;

      if (isWebUrl) {
        _statusMessage = 'Đang tải và bóc tách nội dung bài báo...';
        _progress = 0.40;
        notifyListeners();

        paper = await _backendService.processArticleUrl(
          cleanUrl,
          geminiApiKey: _geminiApiKey,
        );
      } else {
        // Pure ArXiv ID without full URL
        _statusMessage = 'Đang tải PDF từ ArXiv ($arxivId)...';
        _progress = 0.30;
        notifyListeners();

        final pdfBytes = await ArxivService.downloadPdf(arxivId!);
        _stage = IngestionStage.synthesizingGemini;
        _statusMessage = 'Đang gửi lên máy chủ backend để phân tích...';
        _progress = 0.60;
        notifyListeners();

        paper = await _backendService.processFulltextDocument(
          pdfBytes,
          filename: '$arxivId.pdf',
          sourceId: arxivId,
          sourceUrl: ArxivService.getPdfUrl(arxivId),
          geminiApiKey: _geminiApiKey,
        );
      }

      _statusMessage = 'Đang hoàn tất trích xuất cấu trúc & vector embeddings...';
      _progress = 0.95;
      notifyListeners();

      _currentPaper = paper;
      _stage = IngestionStage.completed;
      _statusMessage = 'Đã phân tích bài báo thành công!';
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
        _messages.add(
          ChatMessage.assistant(
            'Tôi đã phân tích thành công bài báo **"${paper.title}"**'
            '${paper.isFallback ? ' *(chế độ dự phòng Gemini Multimodal)*' : ''}.\n\n'
            '💡 **Gợi ý câu hỏi nhanh (bấm vào để hỏi AI ngay):**\n'
            '- 📌 *Nội dung bài báo là j*\n'
            '- 🔑 *Key word chính là j*\n'
            '${paper.suggestedQuestions.isNotEmpty ? '- ❓ *${paper.suggestedQuestions.first}*\n' : ''}\n'
            'Bạn có thể hỏi bằng bất kỳ ngôn ngữ nào, tôi sẽ phản hồi chính xác bằng đúng ngôn ngữ đó!',
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

  // Alias for backward compatibility
  Future<void> processArxivUrl(String inputUrl) => processInputUrl(inputUrl);

  Future<void> processLocalPdf(Uint8List pdfBytes, String filename) async {
    _errorMessage = null;

    try {
      final cleanId = filename.replaceAll('.pdf', '');
      _stage = IngestionStage.synthesizingGemini;
      _statusMessage = 'Đang tải $filename ($progressPercentage%)...';
      _progress = 0.20;
      notifyListeners();

      final paper = await _backendService.processFulltextDocument(
        pdfBytes,
        filename: filename,
        sourceId: cleanId,
        sourceUrl: 'local://$filename',
        geminiApiKey: _geminiApiKey,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final percent = sent / total;
            _progress = 0.20 + percent * 0.50;
            final mbSent = (sent / (1024 * 1024)).toStringAsFixed(1);
            final mbTotal = (total / (1024 * 1024)).toStringAsFixed(1);
            _statusMessage = 'Đang tải file PDF lên: $mbSent MB / $mbTotal MB ($progressPercentage%)';
            notifyListeners();
          }
        },
      );

      _statusMessage = 'Đang bóc tách cấu trúc và tổng hợp nội dung bài báo...';
      _progress = 0.90;
      notifyListeners();

      _currentPaper = paper;
      _stage = IngestionStage.completed;
      _statusMessage = paper.isFallback
          ? 'Đã bóc tách bài báo thành công qua chế độ dự phòng Gemini Multimodal!'
          : 'Đã phân tích bài báo thành công qua GROBID + Gemini!';
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
            'Xin chào! Tôi đã bóc tách bài báo khoa học **"${paper.title}"** theo chuẩn cấu trúc **IMGRaD**:\n\n'
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
    _messages.clear();
    _stage = IngestionStage.idle;
    _statusMessage = '';
    _errorMessage = null;
    notifyListeners();
  }

  /// Selects a paper from local storage without re-downloading or re-uploading (Task F1)
  Future<void> selectRecentPaper(PaperModel paper) async {
    _currentPaper = paper;
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

    if (_geminiApiKey.isEmpty) {
      _messages.add(ChatMessage.user(cleanText));
      _messages.add(
        ChatMessage.assistant(
          '⚠️ Vui lòng cấu hình Google Gemini API Key trong phần **Cài đặt** (biểu tượng bánh răng góc trên bên phải) để kích hoạt tính năng đối thoại AI.',
        ),
      );
      notifyListeners();
      return;
    }

    final userMsg = ChatMessage.user(cleanText);
    final assistantMsg = ChatMessage.streaming();

    _messages.add(userMsg);
    _messages.add(assistantMsg);
    _isStreaming = true;
    notifyListeners();

    try {
      final stream = _backendService.streamPaperChat(
        geminiApiKey: _geminiApiKey,
        paper: _currentPaper!,
        history: _messages,
        userMessage: cleanText,
      );

      await for (final chunk in stream) {
        assistantMsg.content += chunk;
        notifyListeners();
      }

      assistantMsg.isStreaming = false;
      // Persist updated chat conversation (Task F2)
      await _storageService.saveChatHistory(_currentPaper!.id, _messages);
    } catch (e) {
      assistantMsg.isStreaming = false;
      assistantMsg.isError = true;
      assistantMsg.content = 'Lỗi trong quá trình phản hồi: ${e.toString().replaceAll('Exception: ', '')}';
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
    _messages.clear();
    if (_currentPaper != null) {
      _messages.add(
        ChatMessage.assistant('Cuộc trò chuyện đã được đặt lại. Bạn muốn tìm hiểu thêm điều gì về "${_currentPaper!.title}"?'),
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
      final role = msg.role == MessageRole.user ? '### 👤 Người Dùng' : '### 🤖 Trợ Lý PaperChat AI';
      buffer.writeln('$role\n');
      buffer.writeln('${msg.content}\n');
    }

    return buffer.toString();
  }
}
