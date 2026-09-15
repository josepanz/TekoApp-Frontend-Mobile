import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_login_service_provider.dart';

/// El dispositivo actual soporta biometría (huella/rostro enrolada) — independiente de si el
/// usuario ya activó el opt-in (`biometricOptInControllerProvider`, ver `features/auth/providers`).
/// `BiometricLoginService.canAuthenticate()` nunca lanza, así que este provider nunca queda en
/// `AsyncError`: en un dispositivo/entorno sin el canal nativo (incluidos los tests de widget que
/// no lo mockean) resuelve `false` en vez de propagar la excepción.
final biometricDeviceSupportedProvider = FutureProvider<bool>((ref) {
  return ref.watch(biometricLoginServiceProvider).canAuthenticate();
});
