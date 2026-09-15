import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import 'account_deletion_repository_provider.dart';

/// Cancelar una solicitud de borrado en ventana de gracia (banner de `HomeScreen`) — mismo
/// criterio que [RequestDeletionController]: refresca la sesión al terminar para que
/// `deletionScheduledAt` vuelva a `null` y el banner desaparezca solo (ver spec, sección "Banner
/// de ventana de gracia" — la desaparición del banner ES la confirmación visual, no hace falta un
/// mensaje de éxito aparte).
class CancelDeletionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(accountDeletionRepositoryProvider).cancelDeletion();
      await ref.read(sessionProvider.notifier).refreshAfterLogin();
    });
  }
}

final cancelDeletionControllerProvider =
    AsyncNotifierProvider<CancelDeletionController, void>(
  CancelDeletionController.new,
);
