import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../models/account_deletion_failure.dart';
import '../models/deletion_blocker.dart';
import '../providers/request_deletion_controller_provider.dart';

/// "Mi perfil" → "Eliminar cuenta" (ver `openspec/specs/account-deletion.md`). Pantalla informativa
/// (paso 1) + confirmación explícita (paso 2) en una sola vista — la spec permite como mínimo "un
/// checkbox + botón deshabilitado hasta marcarlo" en vez de una pantalla separada, y eso es lo que
/// se implementa acá.
///
/// **Copy sin el número de días de la ventana de gracia a propósito**: es un valor de
/// configuración del backend (`ACCOUNT_DELETION_GRACE_PERIOD_DAYS`, default 14, ver
/// `TekoApp-Backend/openspec/changes/platform-hardening-2026-09/I-01-account-deletion.md`) que
/// puede cambiar sin deploy de Mobile — hardcodear "14 días" acá arriesgaría un copy legal
/// desactualizado. La fecha EXACTA (`deletionScheduledAt`) se muestra recién en el banner de
/// `HomeScreen`, una vez que el backend la calculó y la devolvió.
class AccountDeletionScreen extends ConsumerStatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  ConsumerState<AccountDeletionScreen> createState() =>
      _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends ConsumerState<AccountDeletionScreen> {
  bool _understood = false;
  bool _succeeded = false;

  Future<void> _confirm() async {
    await ref.read(requestDeletionControllerProvider.notifier).submit();
    if (!mounted) return;
    final error = ref.read(requestDeletionControllerProvider).error;
    if (error == null) {
      setState(() => _succeeded = true);
    }
  }

  String _errorMessage(AppLocalizations l10n, Object error) {
    return switch (error) {
      AccountDeletionAlreadyRequestedFailure() =>
        l10n.accountDeletionAlreadyRequestedMessage,
      AccountDeletionNotRequestedFailure() =>
        l10n.accountDeletionNotRequestedMessage,
      AccountDeletionBlockedFailure() => '',
      _ => l10n.accountDeletionErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_succeeded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.accountDeletionScreenTitle)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.accountDeletionSuccessMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TekoButton(
                key: const Key('account_deletion_success_back_button'),
                label: l10n.accountDeletionBackToProfileButton,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(requestDeletionControllerProvider);
    final error = state.error;
    final blockers = error is AccountDeletionBlockedFailure
        ? error.blockers
        : const <DeletionBlocker>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountDeletionScreenTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountDeletionIntroTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(l10n.accountDeletionAnonymizedIntro),
            const SizedBox(height: 12),
            Text(l10n.accountDeletionRetainedIntro),
            const SizedBox(height: 12),
            Text(l10n.accountDeletionGracePeriodIntro),
            const SizedBox(height: 12),
            Text(
              l10n.accountDeletionNoUndoWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (blockers.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l10n.accountDeletionBlockedTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final blocker in blockers)
                _BlockerTile(key: ValueKey(blocker.type), blocker: blocker),
            ],
            if (error != null && error is! AccountDeletionBlockedFailure) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage(l10n, error),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            CheckboxListTile(
              key: const Key('account_deletion_understood_checkbox'),
              value: _understood,
              onChanged: state.isLoading
                  ? null
                  : (checked) => setState(() => _understood = checked ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.accountDeletionConfirmCheckboxLabel),
            ),
            const SizedBox(height: 12),
            TekoButton(
              key: const Key('account_deletion_confirm_button'),
              label: l10n.accountDeletionConfirmButton,
              variant: TekoButtonVariant.destructive,
              loading: state.isLoading,
              onPressed: (_understood && !state.isLoading) ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockerTile extends StatelessWidget {
  const _BlockerTile({super.key, required this.blocker});

  final DeletionBlocker blocker;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (String label, String? route) = switch (blocker.type) {
      DeletionBlockerType.activeService => (
          l10n.accountDeletionBlockerActiveService(blocker.count),
          '/mis-servicios',
        ),
      DeletionBlockerType.pendingPayment => (
          l10n.accountDeletionBlockerPendingPayment(blocker.count),
          '/pagos/historial',
        ),
      DeletionBlockerType.unsignedContract => (
          l10n.accountDeletionBlockerUnsignedContract(blocker.count),
          '/contratos',
        ),
      DeletionBlockerType.unknown => (
          l10n.accountDeletionBlockerUnknown(blocker.count),
          null,
        ),
    };

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: route == null
          ? null
          : TextButton(
              onPressed: () => context.push(route),
              child: Text(l10n.accountDeletionBlockerViewButton),
            ),
    );
  }
}
