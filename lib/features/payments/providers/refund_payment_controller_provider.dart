import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'payment_detail_provider.dart';
import 'payment_history_provider.dart';
import 'payments_repository_provider.dart';

/// Reembolso (parcial o total) de un pago propio — invalida el detalle y el historial para que
/// el monto disponible se refleje al toque (ver `openspec/changes/0004-payments-and-ratings.md`).
class RefundPaymentController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(
    String paymentId, {
    required double amount,
    required String reason,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(paymentsRepositoryProvider)
          .refundPayment(paymentId, amount: amount, reason: reason);
      ref.invalidate(paymentDetailProvider(paymentId));
      ref.invalidate(paymentHistoryProvider);
    });
  }
}

final refundPaymentControllerProvider =
    AsyncNotifierProvider<RefundPaymentController, void>(
  RefundPaymentController.new,
);
