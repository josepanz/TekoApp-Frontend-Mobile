import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository_provider.dart';

/// Estado del opt-in de login biométrico (ver `openspec/specs/biometric-login.md`): `true` si hay
/// credenciales guardadas para repetir el login con huella/rostro. Un solo provider para
/// consultarlo (`profile_screen.dart` lo usa para mostrar el switch; `login_screen.dart`, para
/// decidir si ofrecer el opt-in tras un login exitoso) y para las dos mutaciones del mismo toggle
/// (activar/desactivar) — no son 3 operaciones sueltas, son las dos caras de un solo switch.
class BiometricOptInController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(authRepositoryProvider).hasBiometricCredentials();

  /// Se llama solo tras un login exitoso, con la contraseña recién tipeada (nunca releída de
  /// otro lado) y con confirmación explícita del usuario — nunca automático (ver la spec,
  /// "opt-in explícito, nunca default").
  Future<void> enable({required String email, required String password}) async {
    await ref
        .read(authRepositoryProvider)
        .saveBiometricCredentials(email: email, password: password);
    state = const AsyncData(true);
  }

  /// Desactivación a mano desde el switch de `profile_screen.dart` — sin confirmación adicional,
  /// borrar no tiene el mismo riesgo que guardar.
  Future<void> disable() async {
    await ref.read(authRepositoryProvider).clearBiometricCredentials();
    state = const AsyncData(false);
  }
}

final biometricOptInControllerProvider =
    AsyncNotifierProvider<BiometricOptInController, bool>(
  BiometricOptInController.new,
);
