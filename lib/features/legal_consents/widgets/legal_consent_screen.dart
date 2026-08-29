import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../models/legal_document_version.dart';
import '../providers/legal_consents_controller_provider.dart';
import '../providers/pending_consents_provider.dart';
import 'legal_document_type_labels.dart';

/// Destino de `ConsentGateway` (`/legal/consentimiento`) — presenta TODOS los documentos
/// pendientes de `pendingConsentsProvider` (el guard del backend solo indica "falta consentimiento",
/// no cuál puntual, así que se resuelven todos de una). `context.pop(true)` habilita el reintento
/// del request original que disparó el `403`; `pop(false)` lo deja fallar como estaba.
class LegalConsentScreen extends ConsumerStatefulWidget {
  const LegalConsentScreen({super.key});

  @override
  ConsumerState<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends ConsumerState<LegalConsentScreen> {
  final _checkedReferenceIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = ref.watch(pendingConsentsProvider);
    final controllerState = ref.watch(legalConsentsControllerProvider);

    // `context.pop(true)` habilita el reintento vía `ConsentGateway`; una salida sin valor (back
    // del sistema) resuelve como `false` ahí mismo (`accepted ?? false`), así que no hace falta
    // interceptar el pop del sistema por separado. Solo auto-cierra cuando la lista pasa de
    // "tenía algo" a "vacía" (o sea, tras aceptar todo) — si carga vacía desde el arranque (caso
    // raro, ej. otro dispositivo ya aceptó) se queda mostrando el estado vacío en vez de
    // cerrarse sola antes de que el usuario llegue a ver nada.
    ref.listen(pendingConsentsProvider, (previous, next) {
      final hadPending = previous?.valueOrNull?.isNotEmpty ?? false;
      final isNowEmpty = next.valueOrNull?.isEmpty ?? false;
      if (hadPending && isNowEmpty && mounted) {
        context.pop(true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.legalConsentScreenTitle)),
      body: AsyncStateView<List<LegalDocumentVersion>>(
        isLoading: pending.isLoading,
        hasError: pending.hasError,
        data: pending.valueOrNull,
        isEmpty: pending.valueOrNull?.isEmpty ?? false,
        emptyMessage: l10n.legalConsentNoPendingDocuments,
        builder: (context, documents) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.legalConsentPendingIntro),
            const SizedBox(height: 16),
            for (final document in documents)
              _PendingDocumentTile(
                key: ValueKey(document.referenceId),
                document: document,
                checked: _checkedReferenceIds.contains(document.referenceId),
                onCheckedChanged: (checked) {
                  setState(() {
                    if (checked) {
                      _checkedReferenceIds.add(document.referenceId);
                    } else {
                      _checkedReferenceIds.remove(document.referenceId);
                    }
                  });
                },
              ),
            const SizedBox(height: 24),
            TekoButton(
              key: const Key('legal_consent_accept_button'),
              label: l10n.legalConsentAcceptButton,
              loading: controllerState.isLoading,
              onPressed: documents.isNotEmpty &&
                      _checkedReferenceIds.length == documents.length
                  ? () => _acceptAll(documents)
                  : null,
            ),
            const SizedBox(height: 12),
            TekoButton(
              key: const Key('legal_consent_decline_button'),
              label: l10n.legalConsentCancelButton,
              variant: TekoButtonVariant.ghost,
              onPressed: () => context.pop(false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptAll(List<LegalDocumentVersion> documents) async {
    final controller = ref.read(legalConsentsControllerProvider.notifier);
    for (final document in documents) {
      await controller.accept(document.referenceId);
      if (!mounted) return;
      if (ref.read(legalConsentsControllerProvider).hasError) return;
    }
  }
}

class _PendingDocumentTile extends StatelessWidget {
  const _PendingDocumentTile({
    super.key,
    required this.document,
    required this.checked,
    required this.onCheckedChanged,
  });

  final LegalDocumentVersion document;
  final bool checked;
  final ValueChanged<bool> onCheckedChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              legalDocumentTypeLabel(l10n, document.documentType),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              key: Key('legal_consent_open_${document.referenceId}'),
              onPressed: () => launchUrl(
                Uri.parse(document.contentUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: Text(l10n.legalConsentOpenDocumentButton),
            ),
            CheckboxListTile(
              key: Key('legal_consent_checkbox_${document.referenceId}'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: checked,
              onChanged: (value) => onCheckedChanged(value ?? false),
              title: Text(l10n.legalConsentAcceptCheckboxLabel),
            ),
          ],
        ),
      ),
    );
  }
}
