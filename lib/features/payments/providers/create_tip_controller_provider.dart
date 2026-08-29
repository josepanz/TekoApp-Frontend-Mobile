import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tip.dart';
import '../models/tip_mode.dart';
import 'payment_detail_provider.dart';
import 'payment_history_provider.dart';
import 'payments_repository_provider.dart';

/// Dejar propina para un pago propio ya resuelto (PAID/COMPLETED) — invalida el detalle y el
/// historial para que aparezca al toque, mismo criterio que `RefundPaymentController`.
class CreateTipController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Tip?> submit(
    String paymentReferenceId, {
    required TipMode mode,
    double? percentage,
    double? amount,
  }) async {
    state = const AsyncLoading();
    Tip? created;
    state = await AsyncValue.guard(() async {
      created = await ref.read(paymentsRepositoryProvider).createTip(
            paymentReferenceId,
            mode: mode,
            percentage: percentage,
            amount: amount,
          );
      ref.invalidate(paymentDetailProvider(paymentReferenceId));
      ref.invalidate(paymentHistoryProvider);
    });
    return state.hasError ? null : created;
  }
}

final createTipControllerProvider =
    AsyncNotifierProvider<CreateTipController, void>(
  CreateTipController.new,
);
