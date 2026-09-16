import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/gemini_service.dart';
import 'package:backend/models/paper_model.dart';
import 'package:backend/models/chat_message.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method Not Allowed');
  }

  try {
    final apiKey = request.headers['gemini-api-key'];
    if (apiKey == null || apiKey.isEmpty) {
      return Response(statusCode: 401, body: 'Missing gemini-api-key header');
    }

    final body = await request.json() as Map<String, dynamic>;
    
    final paperData = body['paper'];
    final historyData = body['history'] as List<dynamic>? ?? [];
    final userMessage = body['userMessage'] as String? ?? '';

    if (paperData == null) {
      return Response(statusCode: 400, body: 'Missing paper data');
    }

    final paper = PaperModel.fromJson(paperData as Map<String, dynamic>);
    final history = historyData
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();

    final geminiService = GeminiService(apiKey: apiKey);
    
    // We get a Stream<String> from geminiService
    final textStream = geminiService.streamPaperChat(
      paper: paper,
      history: history,
      userMessage: userMessage,
    );

    // Convert Stream<String> to Stream<List<int>> for chunked transfer
    final byteStream = textStream.map((text) => utf8.encode(text));

    return Response.stream(
      body: byteStream,
      headers: {
        'Content-Type': 'text/plain; charset=utf-8',
        'Transfer-Encoding': 'chunked',
      },
    );
  } catch (e) {
    return Response(statusCode: 500, body: e.toString());
  }
}
