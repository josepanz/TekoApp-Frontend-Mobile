import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/payment.dart';
import '../providers/payment_history_provider.dart';
import 'payment_status_badge.dart';

/// Historial de pagos propios (cliente o profesional, según `appModeProvider`) — ver
/// `openspec/changes/0004-payments-and-ratings.md`.
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final paymentsAsync = ref.watch(paymentHistoryProvider);
    final payments = paymentsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentHistoryTitle)),
      body: AsyncStateView<List<Payment>>(
        isLoading: paymentsAsync.isLoading,
        hasError: paymentsAsync.hasError,
        data: payments,
        isEmpty: payments != null && payments.isEmpty,
        errorMessage: l10n.paymentHistoryError,
        emptyMessage: l10n.paymentHistoryEmpty,
        builder: (context, payments) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final payment = payments[index];
            return GestureDetector(
              key: Key('payment_item_${payment.referenceId}'),
              onTap: () =>
                  context.push('/pagos/historial/${payment.referenceId}'),
              child: TekoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.paymentAmountLabel(payment.totalAmount.round()),
                      ),
                    ),
                    if (payment.tip != null) ...[
                      Tooltip(
                        message: l10n.paymentTipLabel(
                          payment.tip!.amount.round(),
                        ),
                        child: const Icon(
                          Icons.volunteer_activism_outlined,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    PaymentStatusBadge(status: payment.status),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
