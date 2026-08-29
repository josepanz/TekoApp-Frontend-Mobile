import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../promotions/providers/promotions_repository_provider.dart';
import '../models/payment_method.dart';
import 'payments_repository_provider.dart';

/// El backend aceptó la petición pero rechazó el código de promoción en sí (cupo agotado, límite
/// por usuario alcanzado, etc.) — `POST /promotions/apply` responde 200 con `success:false`, no
/// un error HTTP (ver `openspec/decisions.md`), así que esto NO es un `PromotionFailure`.
class PromotionRejected implements Exception {
  const PromotionRejected(this.message);

  final String? message;
}

/// Pagar un servicio completado — si hay código de promoción, lo aplica primero (efecto real,
/// solo acá, nunca como preview) para obtener el `finalAmount` con descuento, y ese es el monto
/// que se manda a `POST /payments`. Ver `openspec/changes/0004-payments-and-ratings.md`.
class PayServiceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String professionalReferenceId,
    required String serviceId,
    required double serviceAmount,
    required PaymentMethod method,
    String? promotionCode,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      var amount = serviceAmount;
      if (promotionCode != null && promotionCode.isNotEmpty) {
        final applied = await ref.read(promotionsRepositoryProvider).apply(
              code: promotionCode,
              serviceAmount: serviceAmount,
              serviceId: serviceId,
            );
        if (!applied.success) {
          throw PromotionRejected(applied.message);
        }
        amount = applied.finalAmount;
      }

      // Paraguay-only por ahora — ningún dominio de la app maneja multi-moneda todavía (mismo
      // criterio que el resto de la UI, que ya muestra "Gs." fijo en otras pantallas).
      await ref.read(paymentsRepositoryProvider).createPayment(
            professionalReferenceId: professionalReferenceId,
            serviceId: serviceId,
            amount: amount,
            currencyCode: 'PYG',
            paymentMethod: method.type,
            paymentProvider: method.provider,
            paymentMethodId: method.referenceId,
          );
    });
  }
}

final payServiceControllerProvider =
    AsyncNotifierProvider<PayServiceController, void>(
  PayServiceController.new,
);
