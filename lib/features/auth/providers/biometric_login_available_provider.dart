import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/biometric_device_supported_provider.dart';
import 'biometric_opt_in_controller_provider.dart';

/// El botón "Ingresar con huella/rostro" de `login_screen.dart` necesita AMBAS cosas: dispositivo
/// con biometría enrolada Y credenciales ya guardadas (opt-in activo). Ninguna de las dos solas
/// alcanza — sin credenciales guardadas no hay nada que leer, y sin soporte de hardware el prompt
/// nativo fallaría igual.
final biometricLoginAvailableProvider = FutureProvider<bool>((ref) async {
  final deviceSupported = await ref.watch(
    biometricDeviceSupportedProvider.future,
  );
  if (!deviceSupported) return false;
  return ref.watch(biometricOptInControllerProvider.future);
});
