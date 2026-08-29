import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../auth/bearer_auth_interceptor.dart';
import '../auth/refresh_token_interceptor.dart';
import '../config/env.dart';
import 'consent_required_interceptor.dart';
import 'envelope_interceptor.dart';
import 'locale_header_interceptor.dart';

/// Único lugar que conoce la URL real del backend y arma el cliente HTTP — ningún `data/` de un
/// dominio crea su propio `Dio` (ver `.claude/rules/flutter-architecture.md`).
///
/// `cookieJar` adjunta/captura el `refreshToken` (viaja solo como cookie httpOnly, ver
/// `openspec/decisions.md`) — se pasa `null` en tests/smoke-checks que no lo necesitan.
/// `onConsentRequired` conecta con `ConsentGateway` (ver `features/legal_consents`) — `null` en
/// tests/smoke-checks que no ejercitan ese flujo, en cuyo caso un `403 CONSENT_REQUIRED` pasa como
/// cualquier otro error sin reintento. Orden de interceptors: Bearer (adjunta el `accessToken`) →
/// `x-lang` (idioma activo, para que el backend traduzca sus propios mensajes de error) →
/// refresh-en-401 (lo renueva si hace falta) → consentimiento-en-403 (pide aceptación y reintenta)
/// → envelope (desenvuelve `{success,data,message,timestamp,path}`, mismo contrato que
/// `core/api-client/client.ts` en TekoApp-Web).
class ApiClient {
  ApiClient({
    Dio? dio,
    CookieJar? cookieJar,
    Future<bool> Function()? onConsentRequired,
  }) : _dio = dio ?? _buildDefaultDio() {
    if (cookieJar != null) {
      _dio.interceptors.add(CookieManager(cookieJar));
    }
    _dio.interceptors.add(BearerAuthInterceptor());
    _dio.interceptors.add(LocaleHeaderInterceptor());
    _dio.interceptors.add(RefreshTokenInterceptor(_dio));
    if (onConsentRequired != null) {
      _dio.interceptors.add(
        ConsentRequiredInterceptor(_dio, onConsentRequired),
      );
    }
    _dio.interceptors.add(EnvelopeInterceptor());
  }

  final Dio _dio;

  Dio get raw => _dio;

  static Dio _buildDefaultDio() {
    return Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json'},
      ),
    );
  }
}
