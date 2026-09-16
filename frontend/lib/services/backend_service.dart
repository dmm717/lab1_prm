import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/paper_model.dart';

class BackendService {
  final Dio _dio;
  final String backendUrl;

  BackendService({
    this.backendUrl = 'http://localhost:8080',
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Checks if backend is alive
  Future<bool> checkIsAlive() async {
    try {
      final response = await _dio.get('$backendUrl/');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends a PDF binary to Dart Backend and returns the parsed PaperModel
  Future<PaperModel> processFulltextDocument(
    Uint8List pdfBytes, {
    String filename = 'paper.pdf',
    String sourceId = '',
    String sourceUrl = '',
    String geminiApiKey = '',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        pdfBytes,
        filename: filename,
      ),
      'sourceId': sourceId,
      'sourceUrl': sourceUrl,
    });

    try {
      final response = await _dio.post(
        '$backendUrl/api/papers/upload',
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'gemini-api-key': geminiApiKey,
          },
        ),
      );

      if (response.statusCode == 200) {
        return PaperModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Backend returned unexpected status code: ${response.statusCode}\n${response.data}',
        );
      }
    } catch (e) {
      throw Exception('Backend processing error: ${e.toString()}');
    }
  }

  /// Streams a conversational chat answer grounded in the full paper context
  Stream<String> streamPaperChat({
    required String geminiApiKey,
    required PaperModel paper,
    required List<ChatMessage> history,
    required String userMessage,
  }) async* {
    if (geminiApiKey.trim().isEmpty) {
      throw Exception('Gemini API Key is not configured. Please set it in Settings.');
    }

    try {
      final response = await _dio.post<ResponseBody>(
        '$backendUrl/api/chat',
        data: {
          'paper': paper.toJson(),
          'history': history.map((e) => e.toJson()).toList(),
          'userMessage': userMessage,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'gemini-api-key': geminiApiKey,
            'Accept': 'text/plain',
          },
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      await for (final chunk in stream) {
        final decoded = utf8.decode(chunk);
        yield decoded;
      }
    } catch (e) {
      throw Exception('Chat error: $e');
    }
  }
}
