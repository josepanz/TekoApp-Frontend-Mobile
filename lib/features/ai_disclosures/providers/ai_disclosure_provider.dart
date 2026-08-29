import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../legal_consents/models/ai_disclosure_entity_type.dart';
import '../models/ai_disclosure.dart';
import 'ai_disclosures_repository_provider.dart';

typedef AiDisclosureKey = ({
  AiDisclosureEntityType entityType,
  String entityReferenceId,
});

/// Lectura puntual — usado por [AiDisclosureBadge] (`shared/widgets/ai_disclosure_badge.dart`) en
/// cualquier pantalla que muestre contenido con posible disclosure.
final aiDisclosureProvider =
    FutureProvider.autoDispose.family<AiDisclosure?, AiDisclosureKey>((
  ref,
  key,
) async {
  return ref
      .watch(aiDisclosuresRepositoryProvider)
      .fetch(key.entityType, key.entityReferenceId);
});
