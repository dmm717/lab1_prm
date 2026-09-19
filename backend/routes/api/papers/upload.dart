import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/paper_model.dart';
import 'package:backend/services/cache_service.dart';
import 'package:backend/services/embedding_service.dart';
import 'package:backend/services/gemini_service.dart';
import 'package:backend/services/grobid_service.dart';
import 'package:backend/services/tei_parser_service.dart';

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
    final formData = await request.formData();
    final file = formData.files['file'];
    final apiKey = _resolveApiKey(request);

    if (apiKey.isEmpty) {
      return Response.json(
        statusCode: 401,
        body: {
          'error': 'Gemini API Key is not configured. Please set it in Settings or .env file.',
          'code': 'MISSING_API_KEY',
        },
      );
    }

    if (file == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'No file uploaded. Key "file" is required in multipart form data.',
          'code': 'NO_FILE_UPLOADED',
        },
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'Uploaded file is empty.',
          'code': 'EMPTY_FILE',
        },
      );
    }

    final uint8Bytes = Uint8List.fromList(bytes);
    final sourceId = formData.fields['sourceId']?.trim().isNotEmpty == true
        ? formData.fields['sourceId']!.trim()
        : file.name.replaceAll('.pdf', '');
    final sourceUrl = formData.fields['sourceUrl']?.trim() ?? '';

    // 1. Check Caching Layer (Task B2)
    final cacheService = CacheService();
    final cacheKey = cacheService.generateKey(sourceId, uint8Bytes);
    final cachedPaper = cacheService.get(cacheKey);

    if (cachedPaper != null) {
      return Response.json(
        body: cachedPaper,
        headers: {
          'X-Cache': 'HIT',
          'X-Fallback': (cachedPaper['isFallback'] == true) ? 'TRUE' : 'FALSE',
        },
      );
    }

    PaperModel paper;
    final geminiService = GeminiService(apiKey: apiKey);

    // 2. Try GROBID processing, Fallback to Gemini Multimodal if GROBID fails (Task B1)
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
      );

      // Synthesize via Gemini
      await geminiService.extractPaperSynthesis(paper);
    } catch (grobidOrTeiError) {
      // Fallback: Use Gemini Multimodal directly on the raw PDF bytes
      try {
        paper = await geminiService.parseAndSynthesizePdfDirectly(
          pdfBytes: uint8Bytes,
          sourceId: sourceId,
          sourceUrl: sourceUrl,
          filename: file.name,
        );
      } catch (geminiFallbackError) {
        final errStr = geminiFallbackError.toString().toLowerCase();
        if (errStr.contains('api_key_invalid') || errStr.contains('api key not valid')) {
          return Response.json(
            statusCode: 401,
            body: {
              'error': 'Google Gemini API Key is invalid or expired.',
              'code': 'INVALID_API_KEY',
            },
          );
        } else if (errStr.contains('quota') || errStr.contains('resource_exhausted') || errStr.contains('429')) {
          return Response.json(
            statusCode: 429,
            body: {
              'error': 'Gemini API quota exceeded or rate limited (429). Please try again in a few moments.',
              'code': 'RATE_LIMIT_EXCEEDED',
            },
          );
        }

        return Response.json(
          statusCode: 500,
          body: {
            'error': 'Failed to process document with GROBID ($grobidOrTeiError) and Gemini Fallback ($geminiFallbackError).',
            'code': 'PROCESSING_FAILED',
          },
        );
      }
    }

    // 3. Compute vector embeddings for paper sections (Optimization via Semantic Embedding)
    try {
      await EmbeddingService.embedPaperSections(paper: paper, apiKey: apiKey);
    } catch (_) {}

    // 4. Save to Cache for subsequent requests
    final paperJson = paper.toJson();
    cacheService.set(cacheKey, paperJson);

    // 5. Return synthesized paper
    return Response.json(
      body: paperJson,
      headers: {
        'X-Cache': 'MISS',
        'X-Fallback': paper.isFallback ? 'TRUE' : 'FALSE',
      },
    );
  } catch (e) {
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('api_key_invalid') || errStr.contains('api key not valid')) {
      return Response.json(
        statusCode: 401,
        body: {
          'error': 'Google Gemini API Key is invalid or expired.',
          'code': 'INVALID_API_KEY',
        },
      );
    } else if (errStr.contains('quota') || errStr.contains('resource_exhausted') || errStr.contains('429')) {
      return Response.json(
        statusCode: 429,
        body: {
          'error': 'Gemini API rate limit or quota exceeded (429). Please wait a moment and retry.',
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
