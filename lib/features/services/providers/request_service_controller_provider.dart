import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai_disclosures/providers/ai_disclosures_repository_provider.dart';
import '../../legal_consents/models/ai_disclosure_entity_type.dart';
import 'services_repository_provider.dart';

/// Mutación de "pedir servicio" — un provider por operación de servidor (ver
/// `.claude/rules/flutter-architecture.md`), separado del repositorio.
class RequestServiceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String title,
    required String description,
    required int categoryId,
    required int serviceTypeId,
    required double latitude,
    required double longitude,
    required String address,
    bool aiAssisted = false,
    String? aiNote,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final created = await ref.read(servicesRepositoryProvider).createService(
            title: title,
            description: description,
            categoryId: categoryId,
            serviceTypeId: serviceTypeId,
            latitude: latitude,
            longitude: longitude,
            address: address,
          );

      if (aiAssisted) {
        // Best-effort, nunca bloquea ni falla el pedido de servicio ya creado — ver
        // `openspec/specs/ai-content-disclosure.md` ("siempre opcional y post-hoc").
        try {
          await ref.read(aiDisclosuresRepositoryProvider).declare(
                entityType: AiDisclosureEntityType.serviceDescription,
                entityReferenceId: created.referenceId,
                note: aiNote,
              );
        } catch (_) {
          // silencioso a propósito
        }
      }
    });
  }
}

final requestServiceControllerProvider =
    AsyncNotifierProvider<RequestServiceController, void>(
  RequestServiceController.new,
);
