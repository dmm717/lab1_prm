import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/grobid_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method Not Allowed', 'code': 'METHOD_NOT_ALLOWED'},
    );
  }
  final alive = await GrobidService().checkIsAlive();
  return Response.json(body: {'online': alive});
}
