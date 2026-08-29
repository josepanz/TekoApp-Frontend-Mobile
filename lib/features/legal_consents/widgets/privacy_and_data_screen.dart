import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../models/content_consent_grant.dart';
import '../models/data_consents_history.dart';
import '../models/legal_consents_failure.dart';
import '../providers/data_consents_history_provider.dart';
import '../providers/legal_consents_controller_provider.dart';
import 'legal_document_type_labels.dart';

/// "Mi perfil" → "Privacidad y datos" — historial de aceptaciones + contenidos con consentimiento
/// de uso otorgado, con revocación (maneja `409 LEGAL_HOLD_ACTIVE` mostrando el motivo real, ver
/// `openspec/specs/data-and-media-consent.md`).
class PrivacyAndDataScreen extends ConsumerWidget {
  const PrivacyAndDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(dataConsentsHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyAndDataScreenTitle)),
      body: AsyncStateView<DataConsentsHistory>(
        isLoading: history.isLoading,
        hasError: history.hasError,
        data: history.valueOrNull,
        builder: (context, data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.privacyDataConsentsHistoryTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (data.consents.isEmpty)
              Text(l10n.privacyDataConsentsHistoryEmpty)
            else
              for (final consent in data.consents)
                ListTile(
                  key: Key('privacy_data_consent_${consent.referenceId}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    legalDocumentTypeLabel(
                      l10n,
                      consent.legalDocumentVersion.documentType,
                    ),
                  ),
                  subtitle: Text(
                    '${consent.legalDocumentVersion.version} · '
                    '${DateFormat.yMd(l10n.localeName).add_Hm().format(consent.acceptedAt)}',
                  ),
                ),
            const SizedBox(height: 24),
            Text(
              l10n.privacyDataContentGrantsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (data.contentGrants.where((g) => g.isActive).isEmpty)
              Text(l10n.privacyDataContentGrantsEmpty)
            else
              for (final grant in data.contentGrants.where((g) => g.isActive))
                _ContentGrantTile(
                  key: ValueKey(grant.referenceId),
                  grant: grant,
                ),
          ],
        ),
      ),
    );
  }
}

class _ContentGrantTile extends ConsumerWidget {
  const _ContentGrantTile({super.key, required this.grant});

  final ContentConsentGrant grant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controllerState = ref.watch(legalConsentsControllerProvider);

    return ListTile(
      key: Key('privacy_data_grant_${grant.referenceId}'),
      contentPadding: EdgeInsets.zero,
      title: Text(grant.contentType.toJson()),
      subtitle: Text(grant.usageScope.toJson()),
      trailing: TextButton(
        key: Key('privacy_data_revoke_${grant.referenceId}'),
        onPressed: controllerState.isLoading
            ? null
            : () => _confirmAndRevoke(context, ref, l10n),
        child: Text(l10n.privacyDataRevokeButton),
      ),
    );
  }

  Future<void> _confirmAndRevoke(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.privacyDataRevokeConfirmTitle),
        content: Text(l10n.privacyDataRevokeConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.legalConsentCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.privacyDataRevokeButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(legalConsentsControllerProvider.notifier)
        .revoke(grant.contentReferenceId);

    if (!context.mounted) return;
    final result = ref.read(legalConsentsControllerProvider);
    final error = result.error;
    if (error is LegalConsentsLegalHoldFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.backendMessage ?? l10n.privacyDataRevokeError),
        ),
      );
    } else if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.privacyDataRevokeError)));
    }
  }
}
