import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'client_basic_auth.dart';
import 'token_storage_keys.dart';

/// Refresh automático (ver `openspec/specs/auth-and-session.md`): un 401 en cualquier request que
/// no sea el propio login/nonce/refresh-token/public-key dispara `POST /auth/refresh-token` una
/// sola vez (el cookie jar de `ApiClient` ya adjunta la cookie `refreshToken` sola, ver
/// `openspec/decisions.md`) y reintenta el request original. Si el refresh también falla, limpia
/// el `accessToken` guardado y deja pasar el error original — el caller lo ve como sesión vencida.
///
/// Simplificación conocida: no coordina refrescos concurrentes (varios 401 a la vez disparan
/// varios refresh en paralelo) — aceptable para el volumen de requests de esta app hoy.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor(this._dio, {FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const _excludedPaths = {
    '/auth/login',
    '/auth/nonce',
    '/auth/public-key',
    '/auth/refresh-token',
  };

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    if (err.response?.statusCode != 401 || _excludedPaths.contains(path)) {
      return handler.next(err);
    }

    try {
      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        options: ClientBasicAuth.options(),
      );
      final newAccessToken = refreshResponse.data?['accessToken'] as String?;
      if (newAccessToken == null) {
        return handler.next(err);
      }

      await _secureStorage.write(
        key: TokenStorageKeys.accessToken,
        value: newAccessToken,
      );

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch<dynamic>(retryOptions);
      return handler.resolve(retryResponse);
    } on DioException {
      await _secureStorage.delete(key: TokenStorageKeys.accessToken);
      return handler.next(err);
    }
  }
}
