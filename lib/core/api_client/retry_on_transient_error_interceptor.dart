import 'package:dio/dio.dart';

/// Reintenta automáticamente un request que falla por un problema transitorio de conexión
/// (timeout, sin conexión) — **solo** si es idempotente (`GET`/`HEAD`) y **solo** si el backend
/// nunca llegó a responder (`err.response == null`). Nunca un `POST`/`PUT`/`PATCH`/`DELETE`
/// (reintentar a ciegas un pago o una calificación duplicaría el efecto) y nunca un 4xx/5xx real
/// (esos sí tuvieron respuesta del backend, no son un paquete perdido). Ver M-02.
///
/// Interceptor propio en vez de `dio_smart_retry`: son ~2 reintentos con backoff simple y este
/// repo ya tuvo una rotura real por una dependencia transitiva (`permission_handler` y
/// `compileSdk`, fase 0015) — no vale la pena la dependencia nueva para esto.
class RetryOnTransientErrorInterceptor extends Interceptor {
  RetryOnTransientErrorInterceptor(
    this._dio, {
    this.maxRetries = 2,
    Duration Function(int attempt) backoff = _defaultBackoff,
  }) : _backoff = backoff;

  final Dio _dio;
  final int maxRetries;
  final Duration Function(int attempt) _backoff;

  static const _idempotentMethods = {'GET', 'HEAD'};

  static const _transientTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  static Duration _defaultBackoff(int attempt) =>
      Duration(milliseconds: 300 * attempt);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_isRetryable(err)) {
      return handler.next(err);
    }

    var lastError = err;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      await Future<void>.delayed(_backoff(attempt));
      try {
        final response = await _dio.fetch<dynamic>(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (retryError) {
        lastError = retryError;
        if (!_isRetryable(retryError)) {
          return handler.next(retryError);
        }
      }
    }
    return handler.next(lastError);
  }

  bool _isRetryable(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    return _idempotentMethods.contains(method) &&
        err.response == null &&
        _transientTypes.contains(err.type);
  }
}
