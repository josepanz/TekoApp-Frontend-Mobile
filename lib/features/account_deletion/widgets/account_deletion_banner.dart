import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/auth/session_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/account_deletion_failure.dart';
import '../providers/cancel_deletion_controller_provider.dart';

/// Banner persistente en `HomeScreen` mientras `deletionScheduledAt != null` (ver
/// `openspec/specs/account-deletion.md`, sección "Banner de ventana de gracia"). Solo se puede
/// descartar cancelando la solicitud — nunca con una X, para que no se pierda de vista por
/// accidente durante la ventana de gracia. Al cancelar con éxito, `deletionScheduledAt` vuelve a
/// `null` (sesión refrescada por el controller) y este widget desaparece solo — esa desaparición
/// ES la confirmación de éxito, no hace falta un mensaje aparte.
class AccountDeletionBanner extends ConsumerWidget {
  const AccountDeletionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session is! SessionAuthenticated) return const SizedBox.shrink();

    final scheduledAt = session.user.deletionScheduledAt;
    if (scheduledAt == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final cancelState = ref.watch(cancelDeletionControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final formattedDate = DateFormat.yMd(l10n.localeName).format(scheduledAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TekoCard(
        key: const Key('account_deletion_banner'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_outlined, color: colorScheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.accountDeletionBannerTitle(formattedDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (cancelState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                _cancelErrorMessage(l10n, cancelState.error!),
                style: TextStyle(color: colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('account_deletion_banner_cancel_button'),
                onPressed: cancelState.isLoading
                    ? null
                    : () => ref
                        .read(cancelDeletionControllerProvider.notifier)
                        .submit(),
                child: cancelState.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.accountDeletionBannerCancelButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cancelErrorMessage(AppLocalizations l10n, Object error) {
    return switch (error) {
      AccountDeletionNotRequestedFailure() =>
        l10n.accountDeletionNotRequestedMessage,
      _ => l10n.accountDeletionErrorGeneric,
    };
  }
}
