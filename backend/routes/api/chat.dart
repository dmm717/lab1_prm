import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/chat_message.dart';
import 'package:backend/models/paper_model.dart';
import 'package:backend/services/gemini_service.dart';

String _resolveApiKey(Request request) {
  final headerKey = request.headers['gemini-api-key']?.trim() ?? '';
  if (headerKey.isNotEmpty) return headerKey;

  final envKey = Platform.environment['GEMINI_API_KEY']?.trim() ?? '';
  if (envKey.isNotEmpty) return envKey;

  for (final path in ['.env', '../.env', 'backend/.env']) {
    try {
      final f = File(path);
      if (f.existsSync()) {
        for (final line in f.readAsLinesSync()) {
          final t = line.trim();
          if (t.startsWith('GEMINI_API_KEY=')) {
            final val = t.substring('GEMINI_API_KEY='.length).trim();
            if (val.isNotEmpty) return val;
          }
        }
      }
    } catch (_) {}
  }
  return '';
}

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method Not Allowed', 'code': 'METHOD_NOT_ALLOWED'},
    );
  }

  try {
    final apiKey = _resolveApiKey(request);
    if (apiKey.isEmpty) {
      return Response.json(
        statusCode: 401,
        body: {
          'error': 'Missing gemini-api-key. Please configure your API key in Settings or .env file.',
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
        body: {'error': 'Missing paper context in request body.', 'code': 'MISSING_PAPER'},
      );
    }

    if (userMessage.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'User message cannot be empty.', 'code': 'EMPTY_MESSAGE'},
      );
    }

    final paper = PaperModel.fromJson(paperData as Map<String, dynamic>);
    final history = historyData
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    final geminiService = GeminiService(apiKey: apiKey);

    // Stream from Gemini with error handling in stream
    final textStream = geminiService.streamPaperChat(
      paper: paper,
      history: history,
      userMessage: userMessage,
    ).handleError((Object error) {
      final errStr = error.toString().toLowerCase();
      if (errStr.contains('api_key_invalid') || errStr.contains('api key not valid')) {
        return '\n\n[ERROR: Invalid Google Gemini API Key. Please check Settings.]';
      } else if (errStr.contains('quota') || errStr.contains('resource_exhausted') || errStr.contains('429')) {
        return '\n\n[ERROR: Gemini API rate limit or quota exceeded. Please wait a few seconds and try again.]';
      }
      return '\n\n[ERROR: ${error.toString().replaceAll('Exception: ', '')}]';
    });

    final byteStream = textStream.map((text) => utf8.encode(text));

    return Response.stream(
      body: byteStream,
      headers: {
        'Content-Type': 'text/plain; charset=utf-8',
      },
    );
  } catch (e) {
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('api_key_invalid') || errStr.contains('api key not valid')) {
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
      body: {'error': e.toString().replaceAll('Exception: ', ''), 'code': 'INTERNAL_ERROR'},
    );
  }
}
