import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/payments/models/payment_method.dart';

Map<String, dynamic> _basePaymentMethodJson() {
  return {
    'id': 1,
    'referenceId': 'pm-uuid-1',
    'userId': 1,
    'name': 'Visa terminada en 4242',
    'type': 'CREDIT_CARD',
    'provider': 'STRIPE',
    'isDefault': true,
    'isActive': true,
    'details': {'cardLast4': '4242'},
    'createdAt': '2026-08-08T10:00:00.000Z',
    'updatedAt': '2026-08-08T10:00:00.000Z',
  };
}

void main() {
  group(
      'PaymentMethod.fromJson — campos de PaymentMethodDetailResponseDTO agregados en M-04',
      () {
    test('parsea todos los campos cuando el backend los devuelve presentes',
        () {
      // Arrange
      final json = {
        ..._basePaymentMethodJson(),
        'externalId': 'pm_stripe_xyz',
        'metadata': {'origen': 'app-mobile'},
        'lastUsedAt': '2026-08-09T10:00:00.000Z',
        'expiresAt': '2028-05-01T00:00:00.000Z',
      };

      // Act
      final method = PaymentMethod.fromJson(json);

      // Assert
      expect(method.userId, 1);
      expect(method.metadata, {'origen': 'app-mobile'});
      expect(
        method.lastUsedAt,
        DateTime.parse('2026-08-09T10:00:00.000Z'),
      );
      expect(method.expiresAt, DateTime.parse('2028-05-01T00:00:00.000Z'));
      expect(method.createdAt, DateTime.parse('2026-08-08T10:00:00.000Z'));
      expect(method.updatedAt, DateTime.parse('2026-08-08T10:00:00.000Z'));
    });

    test(
      'los campos nullable ausentes del JSON (no solo null explícito) parsean a null',
      () {
        // Act — _basePaymentMethodJson() no incluye metadata/lastUsedAt/expiresAt.
        final method = PaymentMethod.fromJson(_basePaymentMethodJson());

        // Assert
        expect(method.metadata, isNull);
        expect(method.lastUsedAt, isNull);
        expect(method.expiresAt, isNull);
        expect(method.externalId, isNull);
      },
    );
  });
}
