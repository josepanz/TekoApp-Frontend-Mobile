import 'package:local_auth/local_auth.dart';

/// Wrapper sobre `local_auth` (ver `openspec/specs/biometric-login.md`) — el login biométrico NO
/// es un segundo factor contra el backend, es una conveniencia local para repetir el login normal
/// (`AuthRepository.login`) sin retipear credenciales tras un logout explícito o un refresh token
/// vencido. Este wrapper existe para que nada fuera de `core/auth` importe `local_auth` directo y
/// para poder inyectar un fake en tests sin depender de un canal de plataforma real.
class BiometricLoginService {
  BiometricLoginService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  /// Cota para el chequeo de capacidad del dispositivo (`canAuthenticate()`) — debería resolver
  /// casi al instante, así que un timeout corto alcanza.
  ///
  /// **Verificado en la práctica** (no solo teorizado): bajo `flutter test` con
  /// `TestWidgetsFlutterBinding` (a diferencia de un `test()` puro sobre la Dart VM, donde SÍ
  /// lanza y el `catch` de abajo alcanza), la llamada real a `local_auth` — sin un canal nativo
  /// que responda — se queda esperando para siempre, sin lanzar ninguna excepción. Un
  /// `try/catch` por sí solo NO alcanza contra eso (no hay nada que atrapar si nunca lanza), así
  /// que hace falta un timeout explícito. Mismo tipo de hallazgo que M-06 con el interceptor de
  /// consentimiento: "nunca cuelga" solo se cumple si hay una cota de tiempo real, no solo un
  /// `catch`.
  static const _capabilityCheckTimeout = Duration(seconds: 5);

  /// Cota para el prompt de autenticación en sí (`authenticate()`) — a diferencia del chequeo de
  /// capacidad, acá SÍ hay una persona real respondiendo, así que la cota tiene que ser generosa.
  /// Mismo valor y misma justificación que `ConsentRequiredInterceptor.consentTimeout` (ver
  /// `core/api_client/consent_required_interceptor.dart`, M-06): 60s alcanza para que alguien
  /// responda al prompt nativo, y acota cualquier escenario donde el canal quede colgado sin
  /// responder en absoluto (el mismo hallazgo de arriba).
  static const _authenticateTimeout = Duration(seconds: 60);

  /// El dispositivo soporta biometría Y tiene al menos una credencial enrolada (huella/rostro).
  /// Nunca cuelga ni lanza: sin biometría enrolada, sin canal nativo disponible, o si el canal
  /// no responde dentro de [_capabilityCheckTimeout], se trata como "no disponible" — el botón
  /// biométrico simplemente no aparece.
  Future<bool> canAuthenticate() async {
    try {
      final supported = await _localAuth.isDeviceSupported().timeout(
            _capabilityCheckTimeout,
            onTimeout: () => false,
          );
      if (!supported) return false;
      return await _localAuth.canCheckBiometrics.timeout(
        _capabilityCheckTimeout,
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  /// Dispara el prompt nativo de huella/rostro. Devuelve `false` si el usuario cancela, si falla
  /// por cualquier motivo, o si no responde dentro de [_authenticateTimeout] — cancelar un
  /// prompt biométrico es una acción válida del usuario, no un error que haya que mostrar en
  /// pantalla (ver la spec).
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _localAuth
          .authenticate(localizedReason: localizedReason, biometricOnly: true)
          .timeout(_authenticateTimeout, onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }
}
