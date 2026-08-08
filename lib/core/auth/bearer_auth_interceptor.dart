import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage_keys.dart';

/// Adjunta `Authorization: Bearer <accessToken>` a toda request que no haya seteado ya su propio
/// header `Authorization` — los endpoints pre-login arman su propio Basic Auth de cliente (ver
/// `client_basic_auth.dart`) y no deben ser pisados. Ver `openspec/specs/api-client.md`.
class BearerAuthInterceptor extends Interceptor {
  BearerAuthInterceptor({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('Authorization')) {
      final token = await _secureStorage.read(
        key: TokenStorageKeys.accessToken,
      );
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
