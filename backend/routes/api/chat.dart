import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/chat_message.dart';
import 'package:backend/models/paper_model.dart';
import 'package:backend/services/gemini_service.dart';
import 'package:backend/core/config/backend_config.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method Not Allowed', 'code': 'METHOD_NOT_ALLOWED'},
    );
  }

  try {
    final apiKey = BackendConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      return Response.json(
        statusCode: 401,
        body: {
          'error':
              'Backend chưa cấu hình GEMINI_API_KEY trong môi trường hoặc backend/.env.',
          'code': 'MISSING_API_KEY',
        },
      );
    }

    final dynamic bodyData = await request.json();
    if (bodyData is! Map<String, dynamic>) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Invalid JSON body payload.', 'code': 'INVALID_JSON'},
      );
    }

    final paperData = bodyData['paper'];
    final historyData = bodyData['history'] as List<dynamic>? ?? [];
    final userMessage = bodyData['userMessage'] as String? ?? '';

    if (paperData == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'Missing paper context in request body.',
          'code': 'MISSING_PAPER',
        },
      );
    }

    if (userMessage.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'User message cannot be empty.',
          'code': 'EMPTY_MESSAGE',
        },
      );
    }

    final paper = PaperModel.fromJson(paperData as Map<String, dynamic>);
    final history = historyData
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    final geminiService = GeminiService(
      apiKey: apiKey,
      modelName: BackendConfig.geminiModel,
    );

    Stream<String> answer() async* {
      try {
        yield* geminiService.streamPaperChat(
          paper: paper,
          history: history,
          userMessage: userMessage,
        );
      } catch (error) {
        yield '\n\n**Lỗi phản hồi Gemini:** ${error.toString().replaceAll('Exception: ', '')}';
      }
    }

    final byteStream = answer().map(utf8.encode);

    return Response.stream(
      body: byteStream,
      headers: {
        'Content-Type': 'text/plain; charset=utf-8',
      },
    );
  } catch (e) {
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('api_key_invalid') ||
        errStr.contains('api key not valid')) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Invalid Gemini API Key.', 'code': 'INVALID_API_KEY'},
      );
    } else if (errStr.contains('quota') || errStr.contains('429')) {
      return Response.json(
        statusCode: 429,
        body: {'error': 'Rate limit exceeded.', 'code': 'RATE_LIMIT_EXCEEDED'},
      );
    }

    return Response.json(
      statusCode: 500,
      body: {
        'error': e.toString().replaceAll('Exception: ', ''),
        'code': 'INTERNAL_ERROR',
      },
    );
  }
}
