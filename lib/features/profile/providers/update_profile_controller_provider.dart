import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import 'profile_repository_provider.dart';

/// Mutación de "Mi perfil" (nombre/apellido/teléfono) — un provider por operación de servidor,
/// separado de `UploadAvatarController` (ver `.claude/rules/flutter-architecture.md`).
class UpdateProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(profileRepositoryProvider).updateMe(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
          );
      // `PUT /auth/me` no devuelve `phoneNumber` en la respuesta (ver
      // `MeResponseDTO`/`openspec/decisions.md`) — se refresca la sesión completa vía
      // `GET /auth/scope` para que la UI muestre datos reales, no un eco optimista del cliente.
      await ref.read(sessionProvider.notifier).refreshAfterLogin();
    });
  }
}

final updateProfileControllerProvider =
    AsyncNotifierProvider<UpdateProfileController, void>(
  UpdateProfileController.new,
);
