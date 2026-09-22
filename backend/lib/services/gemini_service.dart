import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/keyword_model.dart';
import '../models/imgrad_model.dart';
import '../models/paper_model.dart';
import 'chat_context_service.dart';

class GeminiService {
  String apiKey;
  String modelName;

  GeminiService({
    required this.apiKey,
    this.modelName = AppConstants.defaultGeminiModel,
  });

  Future<String> _generateContentWithFallback({
    required List<Content> contents,
    String? systemInstruction,
    String? responseMimeType,
    double temperature = 0.2,
  }) async {
    final candidateModels = [
      modelName,
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-3-flash-preview',
      'gemini-flash-latest',
    ];

    Object? lastError;
    for (final candidate in candidateModels.toSet()) {
      try {
        final model = GenerativeModel(
          model: candidate,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            responseMimeType: responseMimeType,
            temperature: temperature,
          ),
          systemInstruction: systemInstruction != null
              ? Content.system(systemInstruction)
              : null,
        );

        final response = await model.generateContent(contents);
        final text = response.text;
        if (text != null && text.isNotEmpty) {
          return text;
        }
      } catch (e) {
        lastError = e;
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('no longer available') ||
            errStr.contains('503') ||
            errStr.contains('404') ||
            errStr.contains('high demand') ||
            errStr.contains('429')) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('All Gemini models failed: $lastError');
  }

  /// Automatically extracts an executive summary, key contributions,
  /// structured keywords, and starter questions from the parsed paper.
  Future<void> extractPaperSynthesis(PaperModel paper) async {
    if (apiKey.trim().isEmpty) {
      throw Exception(
        'GEMINI_API_KEY is not configured in the backend environment.',
      );
    }

    // Provide title, abstract, and section overview to Gemini
    final prompt =
        '''
Paper Title: ${paper.title}
Authors: ${paper.authors.join(', ')}
Abstract: ${paper.abstractText}

Document Outline & Text:
${paper.fullStructuredText}
''';

    final responseText = await _generateContentWithFallback(
      contents: [Content.text(prompt)],
      systemInstruction: AppConstants.synthesisSystemPrompt,
      responseMimeType: 'application/json',
      temperature: 0.2,
    );

    try {
      final data = jsonDecode(responseText) as Map<String, dynamic>;

      if (data.containsKey('title') && data['title'].toString().isNotEmpty) {
        paper.title = data['title'].toString();
      }

      paper.executiveSummary = data['summary']?.toString() ?? '';

      if (data['imgrad'] is Map<String, dynamic>) {
        paper.imgrad = ImgradModel.fromJson(
          data['imgrad'] as Map<String, dynamic>,
        );
      }

      if (data['contributions'] is List) {
        paper.contributions = (data['contributions'] as List)
            .map((e) => e.toString().trim())
            .toList();
      }

      if (data['keywords'] is List) {
        paper.keywords.clear();
        for (final k in data['keywords'] as List) {
          if (k is Map<String, dynamic>) {
            paper.keywords.add(KeywordModel.fromJson(k));
          }
        }
      }

      if (data['suggested_questions'] is List) {
        paper.suggestedQuestions = (data['suggested_questions'] as List)
            .map((e) => e.toString().trim())
            .toList();
      }
    } catch (e) {
      // Fallback: If json decoding fails, keep raw text as summary
      paper.executiveSummary = responseText;
    }
  }

  /// Streams a conversational chat answer optimized with vector embeddings (Semantic RAG)
  Stream<String> streamPaperChat({
    required PaperModel paper,
    required List<ChatMessage> history,
    required String userMessage,
  }) async* {
    if (apiKey.trim().isEmpty) {
      throw Exception(
        'GEMINI_API_KEY is not configured in the backend environment.',
      );
    }

    final paperContext = ChatContextService.build(
      paper: paper,
      query: userMessage,
    );

    final imgrad = paper.effectiveImgrad;
    final imgradContext =
        '''
=== CẤU TRÚC KHOA HỌC IMGRaD CỦA BÀI BÁO ===
[I - INTRODUCTION / ĐẶT VẤN ĐỀ & MỤC TIÊU]:
${imgrad.introduction.summary}
Điểm chính: ${imgrad.introduction.keyPoints.join('; ')}

[M - METHODOLOGY / PHƯƠNG PHÁP & THIẾT KẾ NGHIÊN CỨU]:
${imgrad.methodology.summary}
Điểm chính: ${imgrad.methodology.keyPoints.join('; ')}

[R - RESULTS / KẾT QUẢ THỰC NGHIỆM & PHÁT HIỆN]:
${imgrad.results.summary}
Điểm chính: ${imgrad.results.keyPoints.join('; ')}

[D - DISCUSSION / THẢO LUẬN, HẠN CHẾ & KẾT LUẬN]:
${imgrad.discussion.summary}
Điểm chính: ${imgrad.discussion.keyPoints.join('; ')}
================================================
''';

    final systemInstruction =
        '''
You are PaperChat AI Desktop, an elite scientific researcher and AI peer reviewer assisting the user in analyzing this academic research paper.

$imgradContext

DETAILED PAPER CONTEXT:
$paperContext

IMGRaD CONVERSATIONAL & CITATION RULES:
1. Ground your answers strictly in the paper and its IMGRaD structure.
2. When answering, explicitly identify, tag, or cite which IMGRaD pillar your findings and evidence belong to:
   * **[I - Đặt vấn đề / Introduction]**: Khi trả lời về bối cảnh, động lực nghiên cứu, câu hỏi nghiên cứu, mục tiêu đóng góp.
   * **[M - Phương pháp / Methodology]**: Khi trả lời về kiến trúc mô hình, thuật toán, công thức toán học, tập dữ liệu thực nghiệm, thiết lập tham số.
   * **[R - Kết quả / Results]**: Khi trả lời về số liệu định lượng, bảng biểu so sánh, kết quả benchmark, kiểm định giả thuyết.
   * **[D - Thảo luận / Discussion]**: Khi trả lời về ý nghĩa thực tiễn, phân tích nguyên nhân, các hạn chế (limitations) của nghiên cứu, và hướng phát triển tương lai (future work).
3. If the user asks for a general paper overview (e.g. "Nội dung bài báo là gì?", "Tóm tắt bài báo"), structure your answer clearly across the 4 pillars:
   - **[I] Đặt Vấn Đề & Mục Tiêu**
   - **[M] Phương Pháp Nghiên Cứu**
   - **[R] Kết Quả Then Chốt**
   - **[D] Thảo Luận & Hạn Chế**
4. STRICT LANGUAGE MATCHING RULE:
   - Automatically detect the exact language used by the user in their query (e.g. Vietnamese, English, Japanese, Chinese, French, German, Spanish, etc.).
   - You MUST respond ENTIRELY in the EXACT SAME LANGUAGE as the user's message.
   - If the user asks in Vietnamese, respond in natural, fluent Vietnamese.
   - If the user asks in English, respond in English.
   - If the user asks in Japanese, respond in Japanese.
   - If the user asks in Chinese, respond in Chinese.
   - NEVER default to English or Vietnamese if the user asks in another language. Always match the input language 100%.
5. Render any mathematical equations using standard LaTeX syntax (\$...\$ or \$\$...\$\$).
6. Format responses with clean Markdown, bullet points, and bold tags.
''';

    final candidateModels = [
      modelName,
      'gemini-3.6-flash',
      'gemini-3.5-flash',
      'gemini-3-flash-preview',
      'gemini-flash-latest',
    ];

    // Build chat history content
    final usableHistory = history
        .where((msg) => !msg.isStreaming && !msg.isError)
        .toList();
    final recentHistory = usableHistory.length > 12
        ? usableHistory.sublist(usableHistory.length - 12)
        : usableHistory;
    while (recentHistory.isNotEmpty &&
        recentHistory.first.role != MessageRole.user) {
      recentHistory.removeAt(0);
    }
    final List<Content> chatContentHistory = [];
    for (final msg in recentHistory) {
      if (msg.role == MessageRole.user) {
        chatContentHistory.add(Content.text(msg.content));
      } else if (msg.role == MessageRole.assistant) {
        chatContentHistory.add(Content.model([TextPart(msg.content)]));
      }
    }

    Object? lastError;
    for (final candidate in candidateModels.toSet()) {
      try {
        final model = GenerativeModel(
          model: candidate,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.3,
          ),
          systemInstruction: Content.system(systemInstruction),
        );

        final chat = model.startChat(history: chatContentHistory);
        final responseStream = chat.sendMessageStream(
          Content.text(userMessage),
        );

        await for (final chunk in responseStream) {
          if (chunk.text != null) {
            yield chunk.text!;
          }
        }
        return; // Success!
      } catch (e) {
        lastError = e;
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('no longer available') ||
            errStr.contains('503') ||
            errStr.contains('404') ||
            errStr.contains('high demand') ||
            errStr.contains('429')) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Chat streaming failed across models: $lastError');
  }
}
