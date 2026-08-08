import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_badge.dart';
import '../models/payment_status.dart';

/// Traduce un `PaymentStatus` a un `TekoBadge` — mismo criterio que `ServiceStatusBadge`.
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, variant) = switch (status) {
      PaymentStatus.pending => (
          l10n.paymentStatusPending,
          TekoBadgeVariant.warning,
        ),
      PaymentStatus.processing => (
          l10n.paymentStatusProcessing,
          TekoBadgeVariant.info,
        ),
      PaymentStatus.completed => (
          l10n.paymentStatusCompleted,
          TekoBadgeVariant.success,
        ),
      PaymentStatus.paid => (l10n.paymentStatusPaid, TekoBadgeVariant.success),
      PaymentStatus.failed => (
          l10n.paymentStatusFailed,
          TekoBadgeVariant.destructive,
        ),
      PaymentStatus.refunded => (
          l10n.paymentStatusRefunded,
          TekoBadgeVariant.info,
        ),
      PaymentStatus.partialRefunded => (
          l10n.paymentStatusPartialRefunded,
          TekoBadgeVariant.info,
        ),
      PaymentStatus.cancelled => (
          l10n.paymentStatusCancelled,
          TekoBadgeVariant.destructive,
        ),
    };
    return TekoBadge(label: label, variant: variant);
  }
}
