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

  /// Credenciales guardadas para login biométrico (ver `openspec/specs/biometric-login.md`) —
  /// opt-in explícito del usuario, nunca escritas por default. `AuthRepository.clearSession()`
  /// (logout) NO borra estas dos claves a propósito: existen justamente para sobrevivir al
  /// logout y repetir el login sin retipear. Solo se borran al desactivar el feature a mano.
  static const biometricEmail = 'biometric_email';
  static const biometricPassword = 'biometric_password';
}
