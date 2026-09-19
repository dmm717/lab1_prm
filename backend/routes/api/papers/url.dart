import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:backend/models/paper_model.dart';
import 'package:backend/services/arxiv_service.dart';
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

String _cleanHtml(String rawHtml) {
  var html = rawHtml;
  html = html.replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ');
  html = html.replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ');
  html = html.replaceAll(RegExp(r'<nav[\s\S]*?</nav>', caseSensitive: false), ' ');
  html = html.replaceAll(RegExp(r'<footer[\s\S]*?</footer>', caseSensitive: false), ' ');
  html = html.replaceAll(RegExp(r'<noscript[\s\S]*?</noscript>', caseSensitive: false), ' ');
  html = html.replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ');
  
  // Extract text within <p>, <h1..h6>, <li>, <blockquote>, <article>
  final textMatches = RegExp(r'<(?:p|h[1-6]|li|blockquote|article)[^>]*>([\s\S]*?)</(?:p|h[1-6]|li|blockquote|article)>', caseSensitive: false)
      .allMatches(html);

  final buffer = StringBuffer();
  if (textMatches.isNotEmpty) {
    for (final match in textMatches) {
      final block = match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), ' ').trim() ?? '';
      if (block.isNotEmpty && block.length > 20) {
        buffer.writeln(block);
        buffer.writeln();
      }
    }
  }

  var text = buffer.toString().trim();
  if (text.length < 100) {
    // Fallback: strip all html tags
    text = html.replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Cap at 30,000 characters to prevent excessive tokens while capturing full article
  if (text.length > 30000) {
    text = text.substring(0, 30000);
  }

  return text;
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
          'error': 'Gemini API Key is not configured. Please set it in Settings or .env file.',
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

    final rawUrl = (bodyData['url'] as String? ?? '').trim();
    if (rawUrl.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'Field "url" is required.', 'code': 'MISSING_URL'},
      );
    }

    final cacheService = CacheService();
    final cacheKey = cacheService.generateKey(rawUrl, Uint8List.fromList(utf8.encode(rawUrl)));
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

    final geminiService = GeminiService(apiKey: apiKey);

    // 1. Check if it is an ArXiv URL
    final arxivId = ArxivService.extractArxivId(rawUrl);
    if (arxivId != null) {
      final pdfBytes = await ArxivService.downloadPdf(arxivId);
      PaperModel paper;

      try {
        final grobidService = GrobidService();
        final teiXml = await grobidService.processFulltextDocument(
          pdfBytes,
          filename: '$arxivId.pdf',
        );
        paper = TeiParserService.parse(
          teiXmlString: teiXml,
          sourceId: arxivId,
          sourceUrl: ArxivService.getPdfUrl(arxivId),
        );
        await geminiService.extractPaperSynthesis(paper);
      } catch (_) {
        paper = await geminiService.parseAndSynthesizePdfDirectly(
          pdfBytes: pdfBytes,
          sourceId: arxivId,
          sourceUrl: ArxivService.getPdfUrl(arxivId),
          filename: '$arxivId.pdf',
        );
      }

      try {
        await EmbeddingService.embedPaperSections(paper: paper, apiKey: apiKey);
      } catch (_) {}

      cacheService.set(cacheKey, paper.toJson());
      return Response.json(body: paper.toJson());
    }

    // 2. Check if it is a direct PDF link
    if (rawUrl.toLowerCase().endsWith('.pdf')) {
      final pdfRes = await http.get(Uri.parse(rawUrl), headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      });

      if (pdfRes.statusCode != 200) {
        return Response.json(
          statusCode: 400,
          body: {'error': 'Could not download PDF from $rawUrl (HTTP ${pdfRes.statusCode})'},
        );
      }

      final pdfBytes = pdfRes.bodyBytes;
      final filename = rawUrl.split('/').last;
      final sourceId = filename.replaceAll('.pdf', '');

      final paper = await geminiService.parseAndSynthesizePdfDirectly(
        pdfBytes: pdfBytes,
        sourceId: sourceId,
        sourceUrl: rawUrl,
        filename: filename,
      );

      try {
        await EmbeddingService.embedPaperSections(paper: paper, apiKey: apiKey);
      } catch (_) {}

      cacheService.set(cacheKey, paper.toJson());
      return Response.json(body: paper.toJson());
    }

    // 3. Web Article (VnExpress, Tuổi Trẻ, News, Blogs, etc.)
    final client = http.Client();
    http.Response webRes;
    try {
      webRes = await client.get(
        Uri.parse(rawUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'vi,en-US,en;q=0.9',
        },
      );
    } finally {
      client.close();
    }

    if (webRes.statusCode != 200) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'Không thể truy cập liên kết bài báo: HTTP ${webRes.statusCode}. Hãy kiểm tra lại đường dẫn.',
          'code': 'HTTP_FETCH_ERROR',
        },
      );
    }

    final contentType = webRes.headers['content-type'] ?? '';
    if (contentType.contains('application/pdf')) {
      final pdfBytes = webRes.bodyBytes;
      final paper = await geminiService.parseAndSynthesizePdfDirectly(
        pdfBytes: pdfBytes,
        sourceId: 'web_pdf',
        sourceUrl: rawUrl,
        filename: 'document.pdf',
      );
      try {
        await EmbeddingService.embedPaperSections(paper: paper, apiKey: apiKey);
      } catch (_) {}
      cacheService.set(cacheKey, paper.toJson());
      return Response.json(body: paper.toJson());
    }

    // Decode HTML body with UTF-8 fallback
    String rawHtml;
    try {
      rawHtml = utf8.decode(webRes.bodyBytes);
    } catch (_) {
      rawHtml = webRes.body;
    }

    final titleMatch = RegExp(r'<title>(.*?)</title>', caseSensitive: false).firstMatch(rawHtml);
    final pageTitle = titleMatch?.group(1)?.replaceAll('&quot;', '"').replaceAll('&amp;', '&').trim() ?? '';

    final descMatch = RegExp(
      r'<meta\s+(?:name|property)=["\x27](?:description|og:description)["\x27]\s+content=["\x27](.*?)["\x27]',
      caseSensitive: false,
    ).firstMatch(rawHtml);
    final metaDescription = descMatch?.group(1)?.trim() ?? '';

    final cleanText = _cleanHtml(rawHtml);

    final paper = await geminiService.parseWebArticle(
      url: rawUrl,
      pageTitle: pageTitle,
      metaDescription: metaDescription,
      articleText: cleanText,
    );

    // Compute semantic embeddings for sections
    try {
      await EmbeddingService.embedPaperSections(paper: paper, apiKey: apiKey);
    } catch (_) {}

    // Cache the analyzed article
    cacheService.set(cacheKey, paper.toJson());

    return Response.json(
      body: paper.toJson(),
      headers: {
        'X-Cache': 'MISS',
        'X-Source': 'WEB_ARTICLE',
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'error': 'Lỗi trong quá trình xử lý bài báo: ${e.toString().replaceAll('Exception: ', '')}',
        'code': 'INTERNAL_ERROR',
      },
    );
  }
}
