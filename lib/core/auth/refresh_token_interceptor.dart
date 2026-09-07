import 'dart:async';

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
/// Refrescos concurrentes coordinados (ver M-01): si dos 401 llegan casi al mismo tiempo,
/// comparten el MISMO `POST /auth/refresh-token` en vuelo en vez de disparar uno cada uno — si
/// el backend rota/invalida el refresh token al usarlo, el segundo hubiera fallado solo y
/// deslogueado al usuario aunque el primero haya salido bien.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor(this._dio, {FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  /// `null` cuando no hay ningún refresh en vuelo. Mientras haya uno, los 401 que lleguen
  /// esperan este mismo resultado en vez de disparar un segundo request.
  Completer<String?>? _refreshCompleter;

  // Comparan contra `RequestOptions.path` (el string relativo que cada call-site pasa a
  // `dio.get/post(...)`), NO contra la URL absoluta. Desde que `/v1` vive en el `baseUrl` de
  // `ApiClient` (ver `api_client.dart`) y ya no se escribe a mano por call-site, estos paths van
  // SIN el prefijo — si alguno de los cuatro vuelve a llevar `/v1` a mano, esta lista deja de
  // matchear en silencio y el interceptor intentaría refrescar sobre su propio login/refresh.
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

    final newAccessToken = await _refreshAccessToken();
    if (newAccessToken == null) {
      return handler.next(err);
    }

    try {
      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken';
      final retryResponse = await _dio.fetch<dynamic>(retryOptions);
      return handler.resolve(retryResponse);
    } on DioException {
      await _secureStorage.delete(key: TokenStorageKeys.accessToken);
      return handler.next(err);
    }
  }

  /// Devuelve el accessToken nuevo, o `null` si el refresh falló (y ya limpió el token
  /// guardado). Si ya hay un refresh en vuelo, espera ese mismo resultado en vez de disparar
  /// un segundo `POST /auth/refresh-token`.
  Future<String?> _refreshAccessToken() {
    final inFlight = _refreshCompleter;
    if (inFlight != null && !inFlight.isCompleted) {
      return inFlight.future;
    }
    final completer = Completer<String?>();
    _refreshCompleter = completer;
    unawaited(_performRefresh(completer));
    return completer.future;
  }

  Future<void> _performRefresh(Completer<String?> completer) async {
    try {
      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh-token',
        options: ClientBasicAuth.options(),
      );
      final newAccessToken = refreshResponse.data?['accessToken'] as String?;
      if (newAccessToken == null) {
        completer.complete(null);
        return;
      }
      await _secureStorage.write(
        key: TokenStorageKeys.accessToken,
        value: newAccessToken,
      );
      completer.complete(newAccessToken);
    } on DioException {
      await _secureStorage.delete(key: TokenStorageKeys.accessToken);
      completer.complete(null);
    } finally {
      // Limpiá SIEMPRE, pase lo que pase, o el interceptor queda trabado esperando para
      // siempre un refresh que ya terminó, y ningún 401 futuro puede disparar uno nuevo.
      _refreshCompleter = null;
    }
  }
}
