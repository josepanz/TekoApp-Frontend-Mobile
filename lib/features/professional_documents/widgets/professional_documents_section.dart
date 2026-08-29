import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_badge.dart';
import '../models/professional_document.dart';
import '../providers/professional_document_file_url_provider.dart';
import '../providers/professional_verified_provider.dart';
import '../providers/public_professional_documents_provider.dart';

/// Sección "Documentos y antecedentes" del lado cliente — badge de verificación (booleano
/// derivado, nunca el documento de antecedentes en sí) + certificaciones/portafolio aprobados.
///
/// No existe todavía una pantalla de "perfil público de profesional" en mobile (la spec de esta
/// fase asumía `lib/features/professionals/widgets/professional_profile_screen.dart`, que no
/// existe) — se embebe acá, en el detalle de servicio, mismo punto de contacto real que ya usa
/// `ProgressTimeline` (Fase 0008). Ver `openspec/decisions.md`.
class ProfessionalDocumentsSection extends ConsumerWidget {
  const ProfessionalDocumentsSection({
    super.key,
    required this.professionalReferenceId,
  });

  final String professionalReferenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final verifiedAsync = ref.watch(
      professionalVerifiedProvider(professionalReferenceId),
    );
    final documentsAsync = ref.watch(
      publicProfessionalDocumentsProvider(professionalReferenceId),
    );
    final documents = documentsAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.professionalDocumentsSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (verifiedAsync.valueOrNull == true) ...[
              const SizedBox(width: 8),
              TekoBadge(
                label: l10n.professionalVerifiedBadge,
                variant: TekoBadgeVariant.success,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        AsyncStateView<List<ProfessionalDocument>>(
          isLoading: documentsAsync.isLoading,
          hasError: documentsAsync.hasError,
          data: documents,
          isEmpty: documents != null && documents.isEmpty,
          errorMessage: l10n.professionalDocumentsSectionError,
          emptyMessage: l10n.professionalDocumentsSectionEmpty,
          builder: (context, documents) => Column(
            children: [
              for (final document in documents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PublicDocumentTile(document: document),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicDocumentTile extends ConsumerWidget {
  const _PublicDocumentTile({required this.document});

  final ProfessionalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(child: Text(document.professionalDocumentType.name)),
        TextButton(
          key: Key('view_professional_document_${document.referenceId}'),
          onPressed: () async {
            final url = await ref.read(
              professionalDocumentFileUrlProvider(document.fileKey).future,
            );
            if (!context.mounted) return;
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.externalApplication,
            );
          },
          child: Text(l10n.professionalDocumentViewButton),
        ),
      ],
    );
  }
}
