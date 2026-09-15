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
    'platformFee': 0.0,
    'isRecurring': false,
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

  group('Payment.fromJson — campos de detalle agregados en M-05', () {
    test('parsea todos los campos cuando el backend los devuelve presentes',
        () {
      // Arrange
      final json = {
        ..._basePaymentJson(),
        'externalTransactionId': 'pi_stripe_123',
        'paymentDetails': {'brand': 'visa'},
        'metadata': {'origen': 'app-mobile'},
        'processedAt': '2026-08-08T10:05:00.000Z',
        'paidAt': '2026-08-08T10:05:01.000Z',
        'failedAt': null,
        'failureReason': null,
        'professionalNetAmount': 88700.0,
        'recurringInterval': 'MONTHLY',
        'nextPaymentDate': '2026-09-08T10:00:00.000Z',
        'lastChangedAt': '2026-08-08T10:05:01.000Z',
      };

      // Act
      final payment = Payment.fromJson(json);

      // Assert
      expect(payment.externalTransactionId, 'pi_stripe_123');
      expect(payment.paymentDetails, {'brand': 'visa'});
      expect(payment.metadata, {'origen': 'app-mobile'});
      expect(payment.processedAt, DateTime.parse('2026-08-08T10:05:00.000Z'));
      expect(payment.paidAt, DateTime.parse('2026-08-08T10:05:01.000Z'));
      expect(payment.failedAt, isNull);
      expect(payment.professionalNetAmount, 88700.0);
      expect(payment.recurringInterval, 'MONTHLY');
      expect(
        payment.nextPaymentDate,
        DateTime.parse('2026-09-08T10:00:00.000Z'),
      );
      expect(
        payment.lastChangedAt,
        DateTime.parse('2026-08-08T10:05:01.000Z'),
      );
      expect(payment.platformFee, 0.0);
      expect(payment.isRecurring, isFalse);
    });

    test(
      'los campos nullable ausentes del JSON (no solo null explícito) parsean a null',
      () {
        // Act — _basePaymentJson() no incluye ninguno de estos campos.
        final payment = Payment.fromJson(_basePaymentJson());

        // Assert
        expect(payment.externalTransactionId, isNull);
        expect(payment.paymentDetails, isNull);
        expect(payment.metadata, isNull);
        expect(payment.processedAt, isNull);
        expect(payment.paidAt, isNull);
        expect(payment.failedAt, isNull);
        expect(payment.failureReason, isNull);
        expect(payment.professionalNetAmount, isNull);
        expect(payment.recurringInterval, isNull);
        expect(payment.nextPaymentDate, isNull);
        expect(payment.lastChangedAt, isNull);
      },
    );
  });
}
