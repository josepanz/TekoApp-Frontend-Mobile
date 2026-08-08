import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_method.dart';
import 'payments_repository_provider.dart';

final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>((ref) {
  return ref.watch(paymentsRepositoryProvider).fetchPaymentMethods();
});
