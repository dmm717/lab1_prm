import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/paper_model.dart';

class BackendService {
  final Dio _dio;
  final String backendUrl;

  BackendService({
    this.backendUrl = const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://localhost:8080',
    ),
    Dio? dio,
  }) : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(minutes: 10),
            ));

  /// Checks the extraction engine through the local backend.
  Future<bool> checkGrobidHealth() async {
    try {
      final response = await _dio.get('$backendUrl/api/grobid/status');
      return response.statusCode == 200 && response.data['online'] == true;
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
      );

      if (response.statusCode == 200) {
        return PaperModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Backend returned status code ${response.statusCode}: ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final errMap = e.response!.data as Map;
        final errorMsg =
            errMap['error']?.toString() ?? 'Server processing error';
        throw Exception(errorMsg);
      } else if (e.response?.data is String &&
          (e.response!.data as String).isNotEmpty) {
        throw Exception(e.response!.data.toString());
      } else if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
          'Không kết nối được backend tại $backendUrl. Kiểm tra tiến trình Dart Frog.',
        );
      }
      throw Exception('Backend communication error: ${e.message}');
    } catch (e) {
      throw Exception('Processing error: ${e.toString()}');
    }
  }

  /// Streams a conversational chat answer grounded in the full paper context
  Stream<String> streamPaperChat({
    required PaperModel paper,
    required List<ChatMessage> history,
    required String userMessage,
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '$backendUrl/api/chat',
        data: {
          'paper': paper.toChatJson(),
          'history': history.map((e) => e.toJson()).toList(),
          'userMessage': userMessage,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/plain'},
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) return;

      yield* utf8.decoder.bind(stream);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is ResponseBody) {
        final body = await utf8.decoder.bind(responseData.stream).join();
        try {
          final error = jsonDecode(body) as Map<String, dynamic>;
          throw Exception(error['error']?.toString() ?? 'Backend không phản hồi.');
        } on FormatException {
          throw Exception(body.isEmpty ? 'Backend không phản hồi.' : body);
        }
      }
      if (responseData is Map && responseData['error'] != null) {
        throw Exception(responseData['error'].toString());
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không kết nối được backend tại $backendUrl.');
      }
      throw Exception('Lỗi kết nối chat: ${e.message}');
    } catch (e) {
      throw Exception('Chat error: $e');
    }
  }
}
