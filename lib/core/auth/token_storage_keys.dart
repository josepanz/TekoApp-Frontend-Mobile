/// Claves de `flutter_secure_storage` — centralizadas para que `AuthRepository` y los
/// interceptors de `dio` (que necesitan la misma clave sin importarse entre sí, ver
/// `bearer_auth_interceptor.dart`/`refresh_token_interceptor.dart`) no dupliquen el string.
class TokenStorageKeys {
  TokenStorageKeys._();

  static const accessToken = 'access_token';

  /// `referenceId` del token FCM ya registrado en el backend (ver
  /// `features/notifications/providers/push_registration_controller.dart`) — necesario para poder
  /// darlo de baja en el logout, el backend no lo resuelve por el token FCM crudo.
  static const fcmTokenReferenceId = 'fcm_token_reference_id';
}
