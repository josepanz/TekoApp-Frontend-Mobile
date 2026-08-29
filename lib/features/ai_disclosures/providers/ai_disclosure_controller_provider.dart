import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../legal_consents/models/ai_disclosure_entity_type.dart';
import 'ai_disclosure_provider.dart';
import 'ai_disclosures_repository_provider.dart';

/// Declarar/retirar un disclosure de forma explícita (ej. una futura pantalla de edición) —
/// invalida [aiDisclosureProvider] para esa entidad al terminar con éxito. El flujo de
/// "declarar al crear contenido" (checkbox en los formularios) NO pasa por acá — es una llamada
/// best-effort directa al repositorio desde el controller de esa feature, para no bloquear el
/// guardado principal si el disclosure falla (ver `openspec/specs/ai-content-disclosure.md`).
class AiDisclosureController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> declare({
    required AiDisclosureEntityType entityType,
    required String entityReferenceId,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(aiDisclosuresRepositoryProvider).declare(
            entityType: entityType,
            entityReferenceId: entityReferenceId,
            note: note,
          );
      final key = (
        entityType: entityType,
        entityReferenceId: entityReferenceId,
      );
      ref.invalidate(aiDisclosureProvider(key));
    });
  }

  Future<void> retract(
    AiDisclosureEntityType entityType,
    String entityReferenceId,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(aiDisclosuresRepositoryProvider)
          .retract(entityType, entityReferenceId);
      final key = (
        entityType: entityType,
        entityReferenceId: entityReferenceId,
      );
      ref.invalidate(aiDisclosureProvider(key));
    });
  }
}

final aiDisclosureControllerProvider =
    AsyncNotifierProvider<AiDisclosureController, void>(
  AiDisclosureController.new,
);
