import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_disclosures/providers/ai_disclosure_provider.dart';
import '../../features/legal_consents/models/ai_disclosure_entity_type.dart';
import '../../l10n/app_localizations.dart';

/// Badge compartido — se muestra en cualquier pantalla que renderice contenido con posible
/// disclosure de IA (de plataforma o autodeclarado). No se reimplementa por feature (ver
/// `openspec/specs/ai-content-disclosure.md`). Silencioso (no renderiza nada) mientras carga, en
/// error, o si no hay disclosure — nunca un placeholder que parpadee en la mayoría de los casos
/// (sin disclosure es el estado normal, no un error).
class AiDisclosureBadge extends ConsumerWidget {
  const AiDisclosureBadge({
    super.key,
    required this.entityType,
    required this.entityReferenceId,
  });

  final AiDisclosureEntityType entityType;
  final String entityReferenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final key = (
      entityType: entityType,
      entityReferenceId: entityReferenceId,
    );
    final disclosureAsync = ref.watch(aiDisclosureProvider(key));

    final disclosure = disclosureAsync.valueOrNull;
    if (disclosure == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.aiDisclosureBadgeLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
