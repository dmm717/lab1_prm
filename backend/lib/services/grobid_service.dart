import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import '../core/config/backend_config.dart';

class GrobidService {
  final Dio _dio;
  String baseUrl;

  GrobidService({String? baseUrl, Dio? dio})
    : baseUrl = baseUrl ?? BackendConfig.grobidUrl,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(
                seconds: 180,
              ), // GROBID parsing large PDFs may take 30-90s
            ),
          );

  /// Checks if the local GROBID Docker container is healthy and responding
  Future<bool> checkIsAlive() async {
    try {
      final response = await _dio.get<String>(
        '$baseUrl${AppConstants.grobidIsAliveEndpoint}',
        options: Options(responseType: ResponseType.plain),
      );
      return response.statusCode == 200 &&
          response.data.toString().trim().toLowerCase() == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Sends a PDF binary to GROBID /api/processFulltextDocument
  /// and returns the structured TEI-XML string
  Future<String> processFulltextDocument(
    Uint8List pdfBytes, {
    String filename = 'paper.pdf',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'input': MultipartFile.fromBytes(
        pdfBytes,
        filename: filename,
      ),
      'consolidateHeader': '1',
      'consolidateCitations': '1',
      'includeRawCitations': '1',
    });

    try {
      final response = await _dio.post<String>(
        '$baseUrl${AppConstants.grobidFulltextEndpoint}',
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Accept': 'application/xml',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        throw Exception(
          'GROBID returned unexpected status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
          'Cannot connect to GROBID at $baseUrl. '
          'Please make sure the Docker container is running: '
          '"docker compose up -d".',
        );
      }
      throw Exception('GROBID processing error: ${e.message}');
    }
  }
}
