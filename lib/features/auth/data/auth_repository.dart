import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api_client/api_client.dart';
import '../../../core/auth/rsa_encryptor.dart';
import '../../../core/config/env.dart';
import '../models/login_failure.dart';
import '../models/login_result.dart';

/// Llamadas a `/auth/*` — equivalente a `features/auth` en TekoApp-Web, pero sin BFF: acá el
/// secret de Basic Auth de cliente vive en la config de la app, no server-side (ver
/// `.claude/rules/auth.md`, sección "Qué NO replicar del BFF de TekoApp-Web").
class AuthRepository {
  AuthRepository(this._apiClient, {FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  static const accessTokenStorageKey = 'access_token';

  Options get _basicAuthOptions {
    const credentials = '${Env.basicAuthClientId}:${Env.basicAuthClientSecret}';
    return Options(
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode(credentials))}',
      },
    );
  }

  /// `GET /auth/public-key` — clave pública RSA para cifrar el login (ver
  /// `openspec/decisions.md`, sección "Cifrado RSA del login").
  Future<String> fetchPublicKeyPem() async {
    final response = await _apiClient.raw.get<Map<String, dynamic>>(
      '/auth/public-key',
      options: _basicAuthOptions,
    );
    return response.data!['publicKeyPem'] as String;
  }

  /// `POST /auth/nonce` — nonce anti-replay de uso único, viaja dentro del payload cifrado.
  Future<String> fetchNonce() async {
    final response = await _apiClient.raw.post<Map<String, dynamic>>(
      '/auth/nonce',
      options: _basicAuthOptions,
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
        options: _basicAuthOptions,
      );

      final accessToken = response.data?['accessToken'] as String?;
      if (accessToken != null) {
        await _secureStorage.write(
          key: accessTokenStorageKey,
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
      throw _classify(error);
    }
  }

  /// 401 → credenciales inválidas (mensaje genérico, nunca distinguir causa). Cualquier otra
  /// respuesta del servidor → servicio no disponible. Sin respuesta (timeout/sin red) → sin
  /// conexión. Nunca colapsar estos 3 casos (ver `specs/auth-and-session.md`).
  LoginFailure _classify(DioException error) {
    if (error.response?.statusCode == 401) {
      return const InvalidCredentialsFailure();
    }
    if (error.response != null) {
      return const ServiceUnavailableFailure();
    }
    return const NoConnectionFailure();
  }
}
