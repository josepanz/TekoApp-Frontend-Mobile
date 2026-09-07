import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api_client/api_client.dart';
import '../../../core/auth/client_basic_auth.dart';
import '../../../core/auth/rsa_encryptor.dart';
import '../../../core/auth/token_storage_keys.dart';
import '../../../core/auth/user_summary.dart';
import '../models/login_failure.dart';
import '../models/login_result.dart';
import '../models/register_failure.dart';
import '../models/register_result.dart';
import '../models/scope_failure.dart';

/// Llamadas a `/auth/*` — equivalente a `features/auth` en TekoApp-Web, pero sin BFF: acá el
/// secret de Basic Auth de cliente vive en la config de la app, no server-side (ver
/// `.claude/rules/auth.md`, sección "Qué NO replicar del BFF de TekoApp-Web").
class AuthRepository {
  AuthRepository(
    this._apiClient, {
    FlutterSecureStorage? secureStorage,
    CookieJar? cookieJar,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _cookieJar = cookieJar;

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  final CookieJar? _cookieJar;

  static const accessTokenStorageKey = TokenStorageKeys.accessToken;

  Future<String?> readAccessToken() =>
      _secureStorage.read(key: TokenStorageKeys.accessToken);

  /// Limpia el estado local de sesión por completo: `accessToken` + la cookie `refreshToken` (si
  /// hay un cookie jar disponible — en tests no siempre se inyecta uno). Se usa tanto en logout
  /// explícito como cuando un refresh automático falla (ver `RefreshTokenInterceptor`) — en ambos
  /// casos el refresh token dejó de ser válido, no tiene sentido conservar la cookie.
  Future<void> clearSession() async {
    await _secureStorage.delete(key: TokenStorageKeys.accessToken);
    await _cookieJar?.deleteAll();
  }

  /// Opt-in de login biométrico (ver `openspec/specs/biometric-login.md`): guarda email +
  /// contraseña en el mismo `flutter_secure_storage` que ya usa `accessToken`. Se llama solo
  /// tras un login exitoso y con confirmación explícita del usuario — nunca automático.
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(
      key: TokenStorageKeys.biometricEmail,
      value: email,
    );
    await _secureStorage.write(
      key: TokenStorageKeys.biometricPassword,
      value: password,
    );
  }

  /// Desactiva el opt-in (switch en `profile_screen.dart`) — a diferencia de `clearSession()`,
  /// esto SÍ tiene que borrar las credenciales guardadas: es la única forma de hacerlo.
  Future<void> clearBiometricCredentials() async {
    await _secureStorage.delete(key: TokenStorageKeys.biometricEmail);
    await _secureStorage.delete(key: TokenStorageKeys.biometricPassword);
  }

  /// Si hay credenciales guardadas, la pantalla de login puede ofrecer el botón biométrico.
  Future<bool> hasBiometricCredentials() async {
    final email =
        await _secureStorage.read(key: TokenStorageKeys.biometricEmail);
    return email != null;
  }

  /// `null` si no hay credenciales guardadas (o quedaron a medio escribir — nunca debería pasar,
  /// pero un email sin password no es un estado usable). El caller repite el login normal
  /// (`login(email:, password:)`) con lo que devuelve acá, nunca un camino de sesión paralelo.
  Future<({String email, String password})?> readBiometricCredentials() async {
    final email =
        await _secureStorage.read(key: TokenStorageKeys.biometricEmail);
    final password = await _secureStorage.read(
      key: TokenStorageKeys.biometricPassword,
    );
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  /// `GET /auth/public-key` — clave pública RSA para cifrar el login (ver
  /// `openspec/decisions.md`, sección "Cifrado RSA del login").
  ///
  /// El prefijo `/v1` (todas las rutas del backend están versionadas, ver `main.ts`) vive en el
  /// `baseUrl` de `ApiClient` — este path va relativo, sin escribirlo a mano (ver M-07 del
  /// WORKPLAN de platform-hardening-2026-09).
  Future<String> fetchPublicKeyPem() async {
    final response = await _apiClient.raw.get<Map<String, dynamic>>(
      '/auth/public-key',
      options: ClientBasicAuth.options(),
    );
    return response.data!['publicKeyPem'] as String;
  }

  /// `POST /auth/nonce` — nonce anti-replay de uso único, viaja dentro del payload cifrado.
  Future<String> fetchNonce() async {
    final response = await _apiClient.raw.post<Map<String, dynamic>>(
      '/auth/nonce',
      options: ClientBasicAuth.options(),
    );
    return response.data!['nonce'] as String;
  }

  /// Flujo completo: `fetchPublicKeyPem` + `fetchNonce` → cifrar `{password, nonce}` → `POST
  /// /auth/login`. Persiste el `accessToken` en almacenamiento seguro cuando el login es exitoso
  /// (el `refreshToken` lo captura el cookie jar de `ApiClient`, nunca viaja en el body — ver
  /// `openspec/decisions.md`).
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final publicKeyPem = await fetchPublicKeyPem();
      final nonce = await fetchNonce();
      final encryptedPassword = RsaEncryptor(
        publicKeyPem,
      ).encryptLoginPayload(password: password, nonce: nonce);

      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'encryptedPassword': encryptedPassword},
        options: ClientBasicAuth.options(),
      );

      final accessToken = response.data?['accessToken'] as String?;
      if (accessToken != null) {
        await _secureStorage.write(
          key: TokenStorageKeys.accessToken,
          value: accessToken,
        );
      }

      return LoginResult(
        success: response.data?['login'] as bool? ?? false,
        requiresNewPassword:
            response.data?['requiredNewPassword'] as bool? ?? false,
        accessToken: accessToken,
      );
    } on DioException catch (error) {
      throw _classifyLogin(error);
    }
  }

  /// `POST /onboarding` (registro público, sin sesión) — cifra `password`/`confirmPassword` cada
  /// uno por separado con RSA-OAEP (sin el envelope `{password, nonce}` del login, ver
  /// `OnboardingApiService.onboarding` del backend: desencripta cada campo suelto).
  Future<RegisterResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) async {
    try {
      final publicKeyPem = await fetchPublicKeyPem();
      final encryptor = RsaEncryptor(publicKeyPem);

      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/onboarding',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': encryptor.encryptValue(password),
          'confirmPassword': encryptor.encryptValue(confirmPassword),
          'acceptTerms': acceptTerms,
        },
        options: ClientBasicAuth.options(),
      );

      final data = response.data!;
      return RegisterResult(
        referenceId: data['referenceId'] as String,
        email: data['email'] as String,
        status: data['status'] as String,
      );
    } on DioException catch (error) {
      throw _classifyRegister(error);
    }
  }

  /// 409 → email ya registrado. Cualquier otra respuesta del servidor → servicio no disponible.
  /// Sin respuesta (timeout/sin red) → sin conexión.
  RegisterFailure _classifyRegister(DioException error) {
    if (error.response?.statusCode == 409) {
      return const EmailAlreadyRegisteredFailure();
    }
    if (error.response != null) {
      return const RegisterServiceUnavailableFailure();
    }
    return const RegisterNoConnectionFailure();
  }

  /// `GET /auth/scope` — datos frescos del usuario (nunca decodificar el JWT localmente, ver
  /// `.claude/rules/auth.md`). Un 401 ya intentó refrescar transparentemente vía
  /// `RefreshTokenInterceptor`; si llega acá es porque el refresh también falló (sesión vencida de
  /// verdad). 5xx/sin conexión son un estado distinto — nunca implican cerrar sesión.
  Future<UserSummary> fetchScope() async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/auth/scope',
      );
      return UserSummary.fromJson(
        response.data!['user'] as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const SessionExpiredFailure();
      }
      throw const ScopeUnavailableFailure();
    }
  }

  /// 401 → credenciales inválidas (mensaje genérico, nunca distinguir causa). Cualquier otra
  /// respuesta del servidor → servicio no disponible. Sin respuesta (timeout/sin red) → sin
  /// conexión. Nunca colapsar estos 3 casos (ver `specs/auth-and-session.md`).
  LoginFailure _classifyLogin(DioException error) {
    if (error.response?.statusCode == 401) {
      return const InvalidCredentialsFailure();
    }
    if (error.response != null) {
      return const ServiceUnavailableFailure();
    }
    return const NoConnectionFailure();
  }
}
