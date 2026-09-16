import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/keyword_model.dart';
import '../models/paper_model.dart';
import '../services/arxiv_service.dart';
import '../services/backend_service.dart';

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

  String _geminiApiKey = '';
  String _selectedModel = AppConstants.defaultGeminiModel;
  
  // We no longer strictly need _grobidUrl here unless you want to keep the setting, 
  // but let's assume Backend runs at a fixed URL for now. 
  // We can repurpose grobidUrl setting as backendUrl in a real scenario.
  String _backendUrl = 'http://localhost:8080';

  bool _isGrobidAlive = false;
  IngestionStage _stage = IngestionStage.idle;
  String _statusMessage = '';
  double _progress = 0.0;
  String? _errorMessage;

  PaperModel? _currentPaper;
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;

  // Getters
  String get grobidUrl => _backendUrl; // alias for compatibility with UI
  String get geminiApiKey => _geminiApiKey;
  String get selectedModel => _selectedModel;
  bool get isGrobidAlive => _isGrobidAlive;
  IngestionStage get stage => _stage;
  String get statusMessage => _statusMessage;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  PaperModel? get currentPaper => _currentPaper;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isStreaming => _isStreaming;
  bool get hasPaper => _currentPaper != null;

  PaperController() {
    _backendService = BackendService(backendUrl: _backendUrl);
    initSettings();
  }

  Future<void> initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString(AppConstants.keyGeminiApiKey) ?? '';
    _backendUrl = prefs.getString(AppConstants.keyGrobidBaseUrl) ?? 'http://localhost:8080';
    _selectedModel = prefs.getString(AppConstants.keySelectedModel) ?? AppConstants.defaultGeminiModel;

    _backendService = BackendService(backendUrl: _backendUrl);

    notifyListeners();
    await checkGrobidHealth();
  }

  Future<void> updateSettings({
    required String apiKey,
    required String grobidUrl, // we treat this as backendUrl now
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

  Future<void> processArxivUrl(String inputUrl) async {
    _errorMessage = null;

    final arxivId = ArxivService.extractArxivId(inputUrl);
    if (arxivId == null) {
      _errorMessage = 'Invalid ArXiv URL or ID. Format: https://arxiv.org/abs/2312.00752';
      notifyListeners();
      return;
    }

    try {
      // 1. Download PDF
      _stage = IngestionStage.downloadingPdf;
      _statusMessage = 'Downloading PDF from ArXiv ($arxivId)...';
      _progress = 0.15;
      notifyListeners();

      final pdfBytes = await ArxivService.downloadPdf(
        arxivId,
        onProgress: (received, total) {
          if (total > 0) {
            _progress = 0.15 + (received / total) * 0.25;
            notifyListeners();
          }
        },
      );

      // 2. Backend Processing (Grobid + TEI + Gemini)
      _stage = IngestionStage.synthesizingGemini;
      _statusMessage = 'Uploading to backend and parsing...';
      _progress = 0.50;
      notifyListeners();

      final paper = await _backendService.processFulltextDocument(
        pdfBytes,
        filename: '$arxivId.pdf',
        sourceId: arxivId,
        sourceUrl: ArxivService.getPdfUrl(arxivId),
        geminiApiKey: _geminiApiKey,
        onSendProgress: (sent, total) {
          if (total > 0) {
             _progress = 0.50 + (sent / total) * 0.20;
             notifyListeners();
          }
        }
      );

      _currentPaper = paper;
      _stage = IngestionStage.completed;
      _statusMessage = 'Paper successfully ingested!';
      _progress = 1.0;

      // Initialize chat with greeting
      _messages.clear();
      _messages.add(
        ChatMessage.assistant(
          'I have analyzed **"${paper.title}"**.\n\n'
          'You can ask me any question about the methodology, results, or click on any of the key concepts on the left to explore deeper!',
        ),
      );

      notifyListeners();
    } catch (e) {
      _stage = IngestionStage.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> processLocalPdf(Uint8List pdfBytes, String filename) async {
    _errorMessage = null;

    try {
      _stage = IngestionStage.synthesizingGemini;
      _statusMessage = 'Uploading $filename and parsing...';
      _progress = 0.50;
      notifyListeners();

      final paper = await _backendService.processFulltextDocument(
        pdfBytes,
        filename: filename,
        sourceId: filename,
        sourceUrl: 'local://file',
        geminiApiKey: _geminiApiKey,
        onSendProgress: (sent, total) {
          if (total > 0) {
             _progress = 0.50 + (sent / total) * 0.20;
             notifyListeners();
          }
        }
      );

      _currentPaper = paper;
      _stage = IngestionStage.completed;
      _statusMessage = 'Paper successfully ingested!';
      _progress = 1.0;

      // Initialize chat with greeting
      _messages.clear();
      _messages.add(
        ChatMessage.assistant(
          'I have analyzed **"${paper.title}"**.\n\n'
          'You can ask me any question about the methodology, results, or click on any of the key concepts on the left to explore deeper!',
        ),
      );

      notifyListeners();
    } catch (e) {
      _stage = IngestionStage.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || _currentPaper == null || _isStreaming) return;

    if (_geminiApiKey.isEmpty) {
      _messages.add(ChatMessage.user(cleanText));
      _messages.add(
        ChatMessage.assistant(
          '⚠️ Please configure your Google Gemini API Key in **Settings** (top-right gear icon) to enable AI chat.',
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
    } catch (e) {
      assistantMsg.isStreaming = false;
      assistantMsg.isError = true;
      assistantMsg.content = 'Error generating response: ${e.toString().replaceAll('Exception: ', '')}';
    } finally {
      _isStreaming = false;
      notifyListeners();
    }
  }

  void askAboutKeyword(KeywordModel keyword) {
    sendMessage(
      'Explain the concept of **"${keyword.term}"** as used in this paper. '
      'How do the authors implement or apply it, and what is its role in the overall methodology?',
    );
  }

  void clearChat() {
    _messages.clear();
    if (_currentPaper != null) {
      _messages.add(
        ChatMessage.assistant('Conversation reset. What else would you like to know about "${_currentPaper!.title}"?'),
      );
    }
    notifyListeners();
  }
}
