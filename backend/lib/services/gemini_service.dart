import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/keyword_model.dart';
import '../models/paper_model.dart';

class GeminiService {
  String apiKey;
  String modelName;

  GeminiService({
    required this.apiKey,
    this.modelName = AppConstants.defaultGeminiModel,
  });

  /// Automatically extracts an executive summary, key contributions,
  /// structured keywords, and starter questions from the parsed paper.
  Future<void> extractPaperSynthesis(PaperModel paper) async {
    if (apiKey.trim().isEmpty) {
      throw Exception('Gemini API Key is not configured. Please set it in Settings.');
    }

    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
      systemInstruction: Content.system(AppConstants.synthesisSystemPrompt),
    );

    // Provide title, abstract, and section overview to Gemini
    final prompt = '''
Paper Title: ${paper.title}
Authors: ${paper.authors.join(', ')}
Abstract: ${paper.abstractText}

Document Outline & Text:
${paper.fullStructuredText}
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final responseText = response.text;

    if (responseText == null || responseText.isEmpty) {
      throw Exception('Received empty synthesis response from Gemini.');
    }

    try {
      final data = jsonDecode(responseText) as Map<String, dynamic>;

      if (data.containsKey('title') && data['title'].toString().isNotEmpty) {
        paper.title = data['title'].toString();
      }

      paper.executiveSummary = data['summary']?.toString() ?? '';

      if (data['contributions'] is List) {
        paper.contributions = (data['contributions'] as List)
            .map((c) => c.toString())
            .toList();
      }

      if (data['keywords'] is List) {
        final List<KeywordModel> extractedKeywords = [];
        for (final item in data['keywords'] as List) {
          if (item is Map<String, dynamic>) {
            extractedKeywords.add(KeywordModel.fromJson(item));
          }
        }
        if (extractedKeywords.isNotEmpty) {
          paper.keywords = extractedKeywords;
        }
      }

      if (data['suggested_questions'] is List) {
        paper.suggestedQuestions = (data['suggested_questions'] as List)
            .map((q) => q.toString())
            .toList();
      }
    } catch (e) {
      // Fallback: If json decoding fails, keep raw text as summary
      paper.executiveSummary = responseText;
    }
  }

  /// Streams a conversational chat answer grounded in the full paper context
  Stream<String> streamPaperChat({
    required PaperModel paper,
    required List<ChatMessage> history,
    required String userMessage,
  }) async* {
    if (apiKey.trim().isEmpty) {
      throw Exception('Gemini API Key is not configured. Please set it in Settings.');
    }

    final systemInstruction = '''
You are PaperChat AI, an elite academic assistant pair-reviewing a research paper with the user.

PAPER CONTEXT:
${paper.fullStructuredText}

GUIDELINES:
1. Ground your answers strictly in the paper provided above.
2. Whenever discussing findings, methodologies, theorems, or data, cite the relevant section (e.g., "[Section 3: Methodology]").
3. Render all mathematical equations using standard LaTeX syntax:
   - Inline math: \$E = mc^2\$
   - Block display math: \$\$\\mathcal{L} = -\\sum y \\log(\\hat{y})\$\$
4. If a question cannot be answered from the paper, state clearly that it is outside the scope of this paper.
5. Provide clear, direct, and insightful explanations.
''';

    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.3,
      ),
      systemInstruction: Content.system(systemInstruction),
    );

    // Build chat history content
    final List<Content> chatContentHistory = [];
    for (final msg in history) {
      if (msg.role == MessageRole.user) {
        chatContentHistory.add(Content.text(msg.content));
      } else if (msg.role == MessageRole.assistant && !msg.isStreaming && !msg.isError) {
        chatContentHistory.add(Content.model([TextPart(msg.content)]));
      }
    }

    final chat = model.startChat(history: chatContentHistory);
    final responseStream = chat.sendMessageStream(Content.text(userMessage));

    await for (final chunk in responseStream) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}
