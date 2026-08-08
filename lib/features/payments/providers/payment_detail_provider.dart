import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment.dart';
import 'payments_repository_provider.dart';

final paymentDetailProvider =
    FutureProvider.autoDispose.family<Payment, String>((ref, id) {
  return ref.watch(paymentsRepositoryProvider).fetchPaymentById(id);
});
