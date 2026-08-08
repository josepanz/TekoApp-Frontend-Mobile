import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/payment_method.dart';
import 'payment_methods_provider.dart';
import 'payments_repository_provider.dart';

/// Alta/marcar-default/baja de un método de pago propio — un `AsyncNotifier` por grupo de
/// mutaciones sobre el mismo recurso (ver `.claude/rules/flutter-architecture.md`), todas
/// invalidan [paymentMethodsProvider] al terminar con éxito.
class PaymentMethodController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> create({
    required String name,
    required PaymentMethodType type,
    required PaymentProviderType provider,
    Map<String, dynamic>? details,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(paymentsRepositoryProvider).createPaymentMethod(
            name: name,
            type: type,
            provider: provider,
            details: details,
          );
      ref.invalidate(paymentMethodsProvider);
    });
  }

  Future<void> setAsDefault(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(paymentsRepositoryProvider).setPaymentMethodAsDefault(id);
      ref.invalidate(paymentMethodsProvider);
    });
  }

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(paymentsRepositoryProvider).deletePaymentMethod(id);
      ref.invalidate(paymentMethodsProvider);
    });
  }
}

final paymentMethodControllerProvider =
    AsyncNotifierProvider<PaymentMethodController, void>(
  PaymentMethodController.new,
);
