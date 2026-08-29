import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data_consents_history_provider.dart';
import 'legal_consents_repository_provider.dart';
import 'pending_consents_provider.dart';

/// Aceptar una versión / revocar un consentimiento de uso — un `AsyncNotifier` por grupo de
/// mutaciones sobre el mismo recurso (ver `.claude/rules/flutter-architecture.md`), invalida
/// [pendingConsentsProvider]/[dataConsentsHistoryProvider] al terminar con éxito. Revocar puede
/// ocultar contenido visible en otras pantallas (portafolio, avatar) — ver
/// `openspec/specs/data-and-media-consent.md`; esta fase no invalida esos providers todavía porque
/// no existen (llegan con `0007`/`0008`).
class LegalConsentsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> accept(String versionReferenceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(legalConsentsRepositoryProvider)
          .acceptConsent(versionReferenceId);
      ref.invalidate(pendingConsentsProvider);
      ref.invalidate(dataConsentsHistoryProvider);
    });
  }

  Future<void> revoke(String contentReferenceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(legalConsentsRepositoryProvider)
          .revokeContentConsent(contentReferenceId);
      ref.invalidate(dataConsentsHistoryProvider);
    });
  }
}

final legalConsentsControllerProvider =
    AsyncNotifierProvider<LegalConsentsController, void>(
  LegalConsentsController.new,
);
