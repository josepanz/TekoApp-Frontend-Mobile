import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/biometric_login_service_provider.dart';
import '../../../core/auth/session_provider.dart';
import '../models/login_failure.dart';
import 'auth_repository_provider.dart';

/// Mutación de "ingresar con huella/rostro" — un provider por operación de servidor (ver
/// `.claude/rules/flutter-architecture.md`), mismo `AsyncValue<void>` que `LoginController` para
/// que `login_screen.dart` pueda reusar el mismo patrón de `ref.listen` (loading → éxito navega).
class BiometricLoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// [localizedReason] viene del widget (necesita `AppLocalizations.of(context)`, no accesible
  /// desde acá) y es el texto que el prompt nativo de `local_auth` le muestra al usuario.
  ///
  /// Si el usuario cancela el prompt biométrico, el estado NUNCA pasa por loading — así
  /// `ref.listen` (que navega en la transición loading→éxito) no confunde un cancelado con un
  /// login exitoso ni con un error real.
  Future<void> submit({required String localizedReason}) async {
    final approved = await ref
        .read(biometricLoginServiceProvider)
        .authenticate(localizedReason: localizedReason);
    if (!approved) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final credentials = await repository.readBiometricCredentials();
      if (credentials == null) {
        // No debería pasar: el botón biométrico solo se muestra si hay credenciales guardadas
        // (ver `biometricLoginAvailableProvider`). Defensivo, no un estado alcanzable desde la UI.
        throw const InvalidCredentialsFailure();
      }

      final result = await repository.login(
        email: credentials.email,
        password: credentials.password,
      );
      if (!result.success) {
        throw const InvalidCredentialsFailure();
      }

      await ref.read(sessionProvider.notifier).refreshAfterLogin();
    });
  }
}

final biometricLoginControllerProvider =
    AsyncNotifierProvider<BiometricLoginController, void>(
  BiometricLoginController.new,
);
