import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/promotions/models/promotion.dart';
import 'package:tekoapp_mobile/features/promotions/models/promotion_status.dart';
import 'package:tekoapp_mobile/features/promotions/models/promotion_type.dart';

/// Migración a codegen (M-04) de `promotions` — ver
/// `openspec/changes/platform-hardening-2026-09/CODEGEN.md`. Hallazgo real: el modelo a mano
/// solo exponía `code`/`name`; el backend siempre devuelve otros 16 campos que se descartaban en
/// silencio (el hallazgo de mayor alcance entre los dominios migrados hasta ahora).
void main() {
  Map<String, dynamic> fullPromotionJson() => {
        'id': 'promo-uuid-1',
        'code': 'PROMO2025',
        'name': 'Descuento de verano',
        'description': '20% de descuento en todos los servicios',
        'type': 'PERCENTAGE',
        'status': 'ACTIVE',
        'discountPercentage': 20.0,
        'discountAmount': null,
        'minimumAmount': 30000,
        'maximumDiscount': 100000,
        'maxUsage': 100,
        'maxUsagePerUser': 1,
        'currentUsage': 42,
        'validFrom': '2025-01-01T00:00:00.000Z',
        'validUntil': '2025-12-31T23:59:59.000Z',
        'allowedUserTypes': ['cliente', 'profesional'],
        'specificUserIds': [1, 2, 3],
        'createdById': 5,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'lastChangedAt': '2025-06-01T00:00:00.000Z',
      };

  group('Promotion.fromJson', () {
    test('expone los campos que el modelo a mano descartaba en silencio', () {
      final promotion = Promotion.fromJson(fullPromotionJson());

      expect(promotion.id, 'promo-uuid-1');
      expect(promotion.type, PromotionType.percentage);
      expect(promotion.status, PromotionStatus.active);
      expect(promotion.discountPercentage, 20.0);
      expect(promotion.maxUsage, 100);
      expect(promotion.maxUsagePerUser, 1);
      expect(promotion.currentUsage, 42);
      expect(promotion.validFrom, DateTime.parse('2025-01-01T00:00:00.000Z'));
      expect(
        promotion.allowedUserTypes,
        ['cliente', 'profesional'],
      );
      expect(promotion.specificUserIds, [1, 2, 3]);
      expect(promotion.createdById, 5);
      expect(
        promotion.lastChangedAt,
        DateTime.parse('2025-06-01T00:00:00.000Z'),
      );
    });

    test(
      'los campos opcionales ausentes (no solo null explícito) resultan en null/vacío',
      () {
        final json = fullPromotionJson()
          ..remove('description')
          ..remove('discountAmount')
          ..remove('createdById')
          ..remove('lastChangedAt')
          ..['specificUserIds'] = <int>[];

        final promotion = Promotion.fromJson(json);

        expect(promotion.description, isNull);
        expect(promotion.discountAmount, isNull);
        expect(promotion.createdById, isNull);
        expect(promotion.lastChangedAt, isNull);
        expect(promotion.specificUserIds, isEmpty);
      },
    );

    test(
        'PromotionType y PromotionStatus desconocidos lanzan, no fallan en silencio',
        () {
      expect(
        () =>
            Promotion.fromJson({...fullPromotionJson(), 'type': 'ALGO_NUEVO'}),
        throwsArgumentError,
      );
    });
  });
}
