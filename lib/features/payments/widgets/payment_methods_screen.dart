import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_badge.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/payment_failure.dart';
import '../models/payment_method.dart';
import '../providers/payment_method_controller_provider.dart';
import '../providers/payment_methods_provider.dart';
import 'payment_method_labels.dart';

/// Modo cliente/profesional (los métodos de pago son de la cuenta, no de un rol específico):
/// listar, marcar default, eliminar (ver `openspec/changes/0004-payments-and-ratings.md`).
class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PaymentMethod method,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.paymentMethodDeleteConfirmTitle),
        content: Text(l10n.paymentMethodDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.paymentMethodDeleteCancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.paymentMethodDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(paymentMethodControllerProvider.notifier)
        .delete(method.referenceId);
    if (!context.mounted) return;
    final state = ref.read(paymentMethodControllerProvider);
    if (state.hasError) {
      final message = switch (state.error) {
        PaymentValidationFailure(:final backendMessage) =>
          backendMessage ?? l10n.paymentMethodGenericError,
        PaymentConflictFailure(:final backendMessage) =>
          backendMessage ?? l10n.paymentMethodGenericError,
        _ => l10n.paymentMethodGenericError,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final methods = methodsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentMethodsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('payment_methods_add_button'),
        onPressed: () => context.push('/pagos/metodos/nuevo'),
        icon: const Icon(Icons.add),
        label: Text(l10n.paymentMethodsAddButton),
      ),
      body: AsyncStateView<List<PaymentMethod>>(
        isLoading: methodsAsync.isLoading,
        hasError: methodsAsync.hasError,
        data: methods,
        isEmpty: methods != null && methods.isEmpty,
        errorMessage: l10n.paymentMethodsError,
        emptyMessage: l10n.paymentMethodsEmpty,
        builder: (context, methods) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: methods.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final method = methods[index];
            return TekoCard(
              key: Key('payment_method_item_${method.referenceId}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          method.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (method.isDefault)
                        TekoBadge(
                          label: l10n.paymentMethodDefaultBadge,
                          variant: TekoBadgeVariant.success,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${paymentMethodTypeLabel(l10n, method.type)} · '
                    '${paymentProviderLabel(l10n, method.provider)}',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!method.isDefault)
                        TextButton(
                          key: Key(
                            'payment_method_set_default_${method.referenceId}',
                          ),
                          onPressed: () => ref
                              .read(paymentMethodControllerProvider.notifier)
                              .setAsDefault(method.referenceId),
                          child: Text(l10n.paymentMethodSetDefaultButton),
                        ),
                      const Spacer(),
                      TextButton(
                        key: Key('payment_method_delete_${method.referenceId}'),
                        onPressed: () =>
                            _confirmDelete(context, ref, l10n, method),
                        child: Text(l10n.paymentMethodDeleteButton),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
