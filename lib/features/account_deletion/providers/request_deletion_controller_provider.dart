import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import 'account_deletion_repository_provider.dart';

/// Paso 2 del flujo de borrado (`openspec/specs/account-deletion.md`) — un provider por
/// operación de servidor, separado de [CancelDeletionController]. `POST
/// /auth/me/deletion-request` no devuelve `deletionScheduledAt` en un formato que la sesión pueda
/// usar directo (el DTO real trae `Date`, la sesión espera el `UserSummary` completo) — se
/// refresca la sesión entera vía `GET /auth/scope` para que el banner de `HomeScreen` quede
/// consistente, mismo patrón que `UpdateProfileController`.
class RequestDeletionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountDeletionRepositoryProvider).requestDeletion();
      await ref.read(sessionProvider.notifier).refreshAfterLogin();
    });
  }
}

final requestDeletionControllerProvider =
    AsyncNotifierProvider<RequestDeletionController, void>(
  RequestDeletionController.new,
);
