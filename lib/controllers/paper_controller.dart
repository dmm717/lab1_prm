import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/keyword_model.dart';
import '../models/paper_model.dart';
import '../services/arxiv_service.dart';
import '../services/gemini_service.dart';
import '../services/grobid_service.dart';
import '../services/tei_parser_service.dart';

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
  late GrobidService _grobidService;
  late GeminiService _geminiService;

  String _grobidUrl = AppConstants.defaultGrobidUrl;
  String _geminiApiKey = '';
  String _selectedModel = AppConstants.defaultGeminiModel;

  bool _isGrobidAlive = false;
  IngestionStage _stage = IngestionStage.idle;
  String _statusMessage = '';
  double _progress = 0.0;
  String? _errorMessage;

  PaperModel? _currentPaper;
  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;

  // Getters
  String get grobidUrl => _grobidUrl;
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
    _grobidService = GrobidService(baseUrl: _grobidUrl);
    _geminiService = GeminiService(apiKey: _geminiApiKey, modelName: _selectedModel);
    initSettings();
  }

  /// Load persisted configuration and check GROBID Docker status
  Future<void> initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString(AppConstants.keyGeminiApiKey) ?? '';
    _grobidUrl = prefs.getString(AppConstants.keyGrobidBaseUrl) ?? AppConstants.defaultGrobidUrl;
    _selectedModel = prefs.getString(AppConstants.keySelectedModel) ?? AppConstants.defaultGeminiModel;

    _grobidService = GrobidService(baseUrl: _grobidUrl);
    _geminiService = GeminiService(apiKey: _geminiApiKey, modelName: _selectedModel);

    notifyListeners();
    await checkGrobidHealth();
  }

  /// Update and persist settings
  Future<void> updateSettings({
    required String apiKey,
    required String grobidUrl,
    required String model,
  }) async {
    _geminiApiKey = apiKey.trim();
    _grobidUrl = grobidUrl.trim();
    _selectedModel = model;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyGeminiApiKey, _geminiApiKey);
    await prefs.setString(AppConstants.keyGrobidBaseUrl, _grobidUrl);
    await prefs.setString(AppConstants.keySelectedModel, _selectedModel);

    _grobidService = GrobidService(baseUrl: _grobidUrl);
    _geminiService = GeminiService(apiKey: _geminiApiKey, modelName: _selectedModel);

    notifyListeners();
    await checkGrobidHealth();
  }

  /// Check connectivity to local GROBID container
  Future<bool> checkGrobidHealth() async {
    _isGrobidAlive = await _grobidService.checkIsAlive();
    notifyListeners();
    return _isGrobidAlive;
  }

  /// Full ingestion pipeline: ArXiv -> Download -> GROBID TEI-XML -> Gemini Synthesis
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

      // 2. GROBID Processing
      _stage = IngestionStage.parsingGrobid;
      _statusMessage = 'Parsing document structure via GROBID (TEI-XML)...';
      _progress = 0.45;
      notifyListeners();

      final teiXml = await _grobidService.processFulltextDocument(
        pdfBytes,
        filename: '$arxivId.pdf',
      );

      // 3. TEI-XML Parsing
      _stage = IngestionStage.analyzingTei;
      _statusMessage = 'Extracting sections, authors, and bibliographic metadata...';
      _progress = 0.70;
      notifyListeners();

      final paper = TeiParserService.parse(
        teiXmlString: teiXml,
        arxivId: arxivId,
        arxivUrl: ArxivService.getPdfUrl(arxivId),
      );

      // 4. Gemini AI Synthesis (Keywords + Summary)
      if (_geminiApiKey.isNotEmpty) {
        _stage = IngestionStage.synthesizingGemini;
        _statusMessage = 'Extracting key concepts, summary, and contributions via Gemini...';
        _progress = 0.85;
        notifyListeners();

        await _geminiService.extractPaperSynthesis(paper);
      }

      // 5. Done
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

  /// Sends a user question to Gemini with full paper context
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
      final stream = _geminiService.streamPaperChat(
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

  /// Shortcut to query Gemini about an extracted keyword
  void askAboutKeyword(KeywordModel keyword) {
    sendMessage(
      'Explain the concept of **"${keyword.term}"** as used in this paper. '
      'How do the authors implement or apply it, and what is its role in the overall methodology?',
    );
  }

  /// Clear current conversation
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
