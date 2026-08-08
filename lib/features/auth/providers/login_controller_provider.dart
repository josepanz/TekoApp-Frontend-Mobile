import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../models/login_failure.dart';
import 'auth_repository_provider.dart';

/// Mutación de login — un provider por operación de servidor (ver
/// `.claude/rules/flutter-architecture.md`). `AsyncValue<void>` porque la pantalla solo necesita
/// saber loading/error/éxito; los datos de sesión en sí viven en `sessionProvider`.
class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);

      // `requiresNewPassword` (usuario legacy sin credencial todavía) es un flujo aparte no
      // cubierto por esta fase (ver openspec/changes/0002-auth-and-design-system.md) — se trata
      // como credenciales inválidas hasta que se implemente esa pantalla explícitamente.
      if (!result.success) {
        throw const InvalidCredentialsFailure();
      }

      await ref.read(sessionProvider.notifier).refreshAfterLogin();
    });
  }
}

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);
