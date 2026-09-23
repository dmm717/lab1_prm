import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/paper_model.dart';
import 'package:backend/core/config/backend_config.dart';
import 'package:backend/services/cache_service.dart';
import 'package:backend/services/gemini_service.dart';
import 'package:backend/services/grobid_service.dart';
import 'package:backend/services/tei_parser_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method Not Allowed', 'code': 'METHOD_NOT_ALLOWED'},
    );
  }

  try {
    final formData = await request.formData();
    final file = formData.files['file'];
    final apiKey = BackendConfig.geminiApiKey;
    final aiEnabled = apiKey.isNotEmpty;

    if (file == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'error':
              'No file uploaded. Key "file" is required in multipart form data.',
          'code': 'NO_FILE_UPLOADED',
        },
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2D) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'Tệp đã chọn không phải PDF hợp lệ.',
          'code': 'INVALID_PDF',
        },
      );
    }

    final uint8Bytes = Uint8List.fromList(bytes);
    final sourceId = file.name.replaceFirst(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    final sourceUrl = formData.fields['sourceUrl']?.trim() ?? '';

    // 1. Check Caching Layer (Task B2)
    final cacheService = CacheService();
    final cacheKey = cacheService.generateKey(sourceId, uint8Bytes);
    final cachedPaper = cacheService.get(cacheKey);

    if (cachedPaper != null && cachedPaper['isFallback'] != true) {
      // Older cache entries can have an empty bibliography even though their
      // saved GROBID TEI contains references. Repair them on the next import.
      final cachedReferences = cachedPaper['references'];
      final cachedTei = cachedPaper['rawTeiXml'];
      if (cachedReferences is List &&
          cachedReferences.isEmpty &&
          cachedTei is String &&
          cachedTei.contains('<listBibl')) {
        final reparsed = TeiParserService.parse(
          teiXmlString: cachedTei,
          sourceId: sourceId,
          sourceUrl: sourceUrl,
          paperId: cacheKey,
        );
        if (reparsed.references.isNotEmpty) {
          cachedPaper['references'] = reparsed.references
              .map((reference) => reference.toJson())
              .toList();
          cacheService.set(cacheKey, cachedPaper);
        }
      }
      if (aiEnabled &&
          (cachedPaper['executiveSummary'] == null ||
              (cachedPaper['executiveSummary'] as String).isEmpty ||
              (cachedPaper['executiveSummary'] as String).startsWith(
                'Chưa thể',
              ))) {
        final cachedModel = PaperModel.fromJson(cachedPaper);
        try {
          await GeminiService(
            apiKey: apiKey,
            modelName: BackendConfig.geminiModel,
          ).extractPaperSynthesis(cachedModel);
          cacheService.set(cacheKey, cachedModel.toJson());
          return Response.json(
            body: cachedModel.toJson(),
            headers: {'X-Cache': 'HIT'},
          );
        } catch (_) {
          // TEI extraction remains usable when Gemini is unavailable.
        }
      }
      return Response.json(
        body: cachedPaper,
        headers: {
          'X-Cache': 'HIT',
          'X-Fallback': (cachedPaper['isFallback'] == true) ? 'TRUE' : 'FALSE',
        },
      );
    }

    PaperModel paper;
    // GROBID is the required extraction engine for local scientific PDFs.
    try {
      final grobidService = GrobidService();
      final teiXml = await grobidService.processFulltextDocument(
        uint8Bytes,
        filename: file.name,
      );

      // Parse TEI-XML into PaperModel
      paper = TeiParserService.parse(
        teiXmlString: teiXml,
        sourceId: sourceId,
        sourceUrl: sourceUrl,
        paperId: cacheKey,
      );
    } catch (error) {
      return Response.json(
        statusCode: 503,
        body: {
          'error':
              'GROBID không thể trích xuất PDF. Kiểm tra Docker và thử lại. Chi tiết: $error',
          'code': 'GROBID_EXTRACTION_FAILED',
        },
      );
    }

    if (paper.sections.isEmpty && paper.abstractText.isEmpty) {
      return Response.json(
        statusCode: 422,
        body: {
          'error':
              'GROBID không tìm thấy nội dung văn bản trong PDF. Tệp có thể là bản quét ảnh.',
          'code': 'NO_EXTRACTED_TEXT',
        },
      );
    }

    if (aiEnabled) {
      try {
        await GeminiService(
          apiKey: apiKey,
          modelName: BackendConfig.geminiModel,
        ).extractPaperSynthesis(paper);
      } catch (error) {
        // Keep the extracted TEI content available even when synthesis fails.
        paper.executiveSummary = 'Chưa thể tổng hợp bằng Gemini: $error';
      }
    }

    // Save the extracted paper. Chat retrieval runs locally without embeddings.
    final paperJson = paper.toJson();
    cacheService.set(cacheKey, paperJson);

    // Return synthesized paper
    return Response.json(
      body: paperJson,
      headers: {
        'X-Cache': 'MISS',
        'X-Fallback': paper.isFallback ? 'TRUE' : 'FALSE',
      },
    );
  } catch (e) {
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('api_key_invalid') ||
        errStr.contains('api key not valid')) {
      return Response.json(
        statusCode: 401,
        body: {
          'error': 'Google Gemini API Key is invalid or expired.',
          'code': 'INVALID_API_KEY',
        },
      );
    } else if (errStr.contains('quota') ||
        errStr.contains('resource_exhausted') ||
        errStr.contains('429')) {
      return Response.json(
        statusCode: 429,
        body: {
          'error':
              'Gemini API rate limit or quota exceeded (429). Please wait a moment and retry.',
          'code': 'RATE_LIMIT_EXCEEDED',
        },
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
