import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  return (context) async {
    final request = context.request;

    // Handle preflight CORS OPTIONS requests
    if (request.method == HttpMethod.options) {
      return Response(
        statusCode: 204,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin, Content-Type, Accept, X-Requested-With',
          'Access-Control-Max-Age': '86400',
        },
      );
    }

    final response = await handler(context);

    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, X-Requested-With',
      },
    );
  };
}
