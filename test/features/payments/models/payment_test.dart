import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/payments/models/payment.dart';

Map<String, dynamic> _basePaymentJson({Map<String, dynamic>? refundDetails}) {
  return {
    'id': 1,
    'referenceId': 'pay-uuid-1',
    'userId': 1,
    'professionalId': 2,
    'serviceId': 'svc-uuid-1',
    'amount': 100000.0,
    'currencyCode': 'PYG',
    'fee': 0.0,
    'tax': 0.0,
    'totalAmount': 100000.0,
    'status': 'COMPLETED',
    'paymentMethod': 'CREDIT_CARD',
    'paymentProvider': 'STRIPE',
    'transactionId': 'txn-1',
    'createdAt': '2026-08-08T10:00:00.000Z',
    if (refundDetails != null) 'refundDetails': refundDetails,
  };
}

void main() {
  group('Payment.amountAvailableForRefund', () {
    test('es el totalAmount completo cuando nunca se reembolsó nada', () {
      // Arrange
      final payment = Payment.fromJson(_basePaymentJson());

      // Act & Assert
      expect(payment.refundedAmount, 0);
      expect(payment.amountAvailableForRefund, 100000.0);
    });

    test(
        'descuenta el refundedAmount acumulado de reembolsos parciales previos',
        () {
      // Arrange
      final payment = Payment.fromJson(
        _basePaymentJson(refundDetails: {'refundedAmount': 40000}),
      );

      // Act & Assert
      expect(payment.refundedAmount, 40000);
      expect(payment.amountAvailableForRefund, 60000.0);
    });

    test('llega a 0 disponible tras un reembolso total', () {
      // Arrange
      final payment = Payment.fromJson(
        _basePaymentJson(refundDetails: {'refundedAmount': 100000}),
      );

      // Act & Assert
      expect(payment.amountAvailableForRefund, 0.0);
    });
  });
}
