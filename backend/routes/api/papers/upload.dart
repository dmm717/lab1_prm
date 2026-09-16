import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/grobid_service.dart';
import 'package:backend/services/tei_parser_service.dart';
import 'package:backend/services/gemini_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method Not Allowed');
  }

  try {
    final formData = await request.formData();
    final file = formData.files['file'];
    
    // Check if API key is provided in headers
    final apiKey = request.headers['gemini-api-key'] ?? '';
    
    if (file == null) {
      return Response(statusCode: 400, body: 'No file uploaded. Key "file" is required.');
    }

    final bytes = await file.readAsBytes();
    final uint8Bytes = Uint8List.fromList(bytes);
    
    // 1. Process with GROBID
    final grobidService = GrobidService(); // Uses default localhost:8070
    final teiXml = await grobidService.processFulltextDocument(uint8Bytes, filename: file.name);

    // Extract optional sourceId and sourceUrl from form data if provided
    final sourceId = formData.fields['sourceId'] ?? file.name.replaceAll('.pdf', '');
    final sourceUrl = formData.fields['sourceUrl'] ?? '';

    // 2. Parse TEI XML
    final paper = TeiParserService.parse(
      teiXmlString: teiXml,
      sourceId: sourceId,
      sourceUrl: sourceUrl,
    );

    // 3. Synthesize with Gemini
    if (apiKey.isNotEmpty) {
      final geminiService = GeminiService(apiKey: apiKey);
      await geminiService.extractPaperSynthesis(paper);
    }

    // 4. Return the complete paper model as JSON
    return Response.json(body: paper.toJson());
  } catch (e) {
    return Response.json(statusCode: 500, body: {'error': e.toString()});
  }
}
