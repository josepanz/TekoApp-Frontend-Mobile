import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_input.dart';
import '../models/payment.dart';
import '../models/payment_failure.dart';
import '../models/payment_status.dart';
import '../providers/payment_detail_provider.dart';
import '../providers/refund_payment_controller_provider.dart';
import 'payment_status_badge.dart';

/// Detalle de un pago por su `id` (UUID) + reembolso (parcial o total) — ver
/// `openspec/changes/0004-payments-and-ratings.md`.
class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({super.key, required this.paymentId});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final paymentAsync = ref.watch(paymentDetailProvider(paymentId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentDetailTitle)),
      body: switch (paymentAsync) {
        AsyncData(:final value) => _PaymentDetailBody(payment: value),
        AsyncError() => Center(child: Text(l10n.paymentDetailError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PaymentDetailBody extends ConsumerWidget {
  const _PaymentDetailBody({required this.payment});

  final Payment payment;

  bool get _isRefundable =>
      (payment.status == PaymentStatus.completed ||
          payment.status == PaymentStatus.partialRefunded) &&
      payment.amountAvailableForRefund > 0;

  Future<void> _openRefundDialog(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.paymentRefundDialogTitle),
        content: Form(
          key: formKey,
          child: TekoInput(
            key: const Key('refund_amount_field'),
            label: l10n.paymentRefundAmountLabel,
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              final parsed = double.tryParse((value ?? '').trim());
              if (parsed == null ||
                  parsed <= 0 ||
                  parsed > payment.amountAvailableForRefund) {
                return l10n.paymentRefundAmountRequired;
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.paymentRefundCancel),
          ),
          TextButton(
            key: const Key('refund_dialog_submit_button'),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.of(context).pop(true);
            },
            child: Text(l10n.paymentRefundSubmit),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final amount = double.parse(amountController.text.trim());
    await ref
        .read(refundPaymentControllerProvider.notifier)
        .submit(payment.id, amount: amount, reason: 'customer_request');
    if (!context.mounted) return;

    final state = ref.read(refundPaymentControllerProvider);
    final message = switch (state.error) {
      null => l10n.paymentRefundSuccess,
      PaymentValidationFailure(:final backendMessage) =>
        backendMessage ?? l10n.paymentRefundError,
      PaymentConflictFailure(:final backendMessage) =>
        backendMessage ?? l10n.paymentRefundError,
      _ => l10n.paymentRefundError,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final refundState = ref.watch(refundPaymentControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.paymentAmountLabel(payment.totalAmount.round()),
                  style: textTheme.titleLarge,
                ),
              ),
              PaymentStatusBadge(status: payment.status),
            ],
          ),
          if (payment.refundedAmount > 0) ...[
            const SizedBox(height: 8),
            Text(
              l10n.paymentAvailableForRefundLabel(
                payment.amountAvailableForRefund.round(),
              ),
            ),
          ],
          if (_isRefundable) ...[
            const SizedBox(height: 24),
            TekoButton(
              key: const Key('payment_refund_button'),
              label: l10n.paymentRefundButton,
              loading: refundState.isLoading,
              onPressed: refundState.isLoading
                  ? null
                  : () => _openRefundDialog(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}
