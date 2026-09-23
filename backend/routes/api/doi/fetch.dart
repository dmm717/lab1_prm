import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/doi_fetch_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;

  if (request.method != HttpMethod.get && request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method Not Allowed'},
    );
  }

  String title = '';
  String? doi;

  if (request.method == HttpMethod.get) {
    title = request.uri.queryParameters['title'] ?? '';
    doi = request.uri.queryParameters['doi'];
  } else {
    try {
      final json = await request.json() as Map<String, dynamic>;
      title = json['title']?.toString() ?? '';
      doi = json['doi']?.toString();
    } catch (_) {}
  }

  if (title.trim().isEmpty && (doi == null || doi.trim().isEmpty)) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Either "title" or "doi" parameter is required.'},
    );
  }

  final fetchService = DoiFetchService();
  final result = await fetchService.fetchMetadata(title: title, doi: doi);

  if (result == null) {
    return Response.json(
      statusCode: 404,
      body: {'error': 'DOI metadata not found on CrossRef.'},
    );
  }

  return Response.json(body: result.toJson());
}
