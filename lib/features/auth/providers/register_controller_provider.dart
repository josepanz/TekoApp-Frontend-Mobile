import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository_provider.dart';

/// Mutación de registro — un provider por operación de servidor (ver
/// `.claude/rules/flutter-architecture.md`). No inicia sesión automáticamente: el usuario queda
/// `PENDING_VERIFICATION` (ver `OnboardingUserResponseDTO.status`) y debe loguearse aparte una vez
/// verificado el email — misma UX que Web (`register-form.tsx` redirige a `/login`).
class RegisterController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required bool acceptTerms,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phoneNumber: phoneNumber,
            password: password,
            confirmPassword: confirmPassword,
            acceptTerms: acceptTerms,
          );
    });
  }
}

final registerControllerProvider =
    AsyncNotifierProvider<RegisterController, void>(RegisterController.new);
