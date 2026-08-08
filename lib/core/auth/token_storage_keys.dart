/// Claves de `flutter_secure_storage` — centralizadas para que `AuthRepository` y los
/// interceptors de `dio` (que necesitan la misma clave sin importarse entre sí, ver
/// `bearer_auth_interceptor.dart`/`refresh_token_interceptor.dart`) no dupliquen el string.
class TokenStorageKeys {
  TokenStorageKeys._();

  static const accessToken = 'access_token';
}
