import 'dart:convert';

import 'package:dio/dio.dart';

import '../config/env.dart';

/// Basic Auth de *cliente* (no de usuario) que exigen los endpoints pre-login (`/auth/nonce`,
/// `/auth/login`, `/auth/public-key`, `/auth/refresh-token` — ver `BasicAuthGuard` del backend).
/// Centralizado porque tanto `AuthRepository` como `RefreshTokenInterceptor` lo necesitan.
class ClientBasicAuth {
  ClientBasicAuth._();

  static Options options() {
    const credentials = '${Env.basicAuthClientId}:${Env.basicAuthClientSecret}';
    return Options(
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode(credentials))}',
      },
    );
  }
}
