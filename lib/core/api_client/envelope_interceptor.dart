import 'package:dio/dio.dart';

/// El backend envuelve toda respuesta exitosa en `{success, data, message, timestamp, path}`
/// (mismo `TransformInterceptor` que ya documenta `TekoApp-Web/src/core/api-client/client.ts`).
/// Este interceptor desenvuelve `data` para que el resto del código nunca tenga que acordarse del
/// wrapper — equivalente a `isBackendEnvelope`/`apiFetch` del lado web.
class EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is Map<String, dynamic> &&
        body.containsKey('success') &&
        body.containsKey('data')) {
      response.data = body['data'];
    }
    handler.next(response);
  }
}
