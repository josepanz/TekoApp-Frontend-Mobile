import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/ratings/models/rating.dart';

void main() {
  group('Rating.fromJson', () {
    test(
        'parsea una reseña anónima con userId y professionalId nulos sin lanzar',
        () {
      final json = {
        'id': 1,
        'referenceId': 'r-1',
        'userId': null,
        'professionalId': null,
        'type': 'CLIENT_TO_PROFESSIONAL',
        'rating': 5,
        'review': 'Excelente',
        'isAnonymous': true,
        'isReported': false,
        'isActive': true,
        'createdAt': '2026-09-01T10:00:00.000Z',
      };

      final rating = Rating.fromJson(json);

      expect(rating.userId, isNull);
      expect(rating.professionalId, isNull);
      expect(rating.isAnonymous, isTrue);
    });

    test('parsea una reseña no anónima con ambos ids presentes (no-regresión)',
        () {
      final json = {
        'id': 2,
        'referenceId': 'r-2',
        'userId': 10,
        'professionalId': 20,
        'type': 'CLIENT_TO_PROFESSIONAL',
        'rating': 4,
        'review': 'Muy bueno',
        'isAnonymous': false,
        'isReported': false,
        'isActive': true,
        'createdAt': '2026-09-01T10:00:00.000Z',
      };

      final rating = Rating.fromJson(json);

      expect(rating.userId, 10);
      expect(rating.professionalId, 20);
      expect(rating.isAnonymous, isFalse);
    });

    test('una lista mixta (una anónima + una normal) parsea entera', () {
      final jsonList = [
        {
          'id': 1,
          'referenceId': 'r-1',
          'userId': null,
          'professionalId': null,
          'type': 'CLIENT_TO_PROFESSIONAL',
          'rating': 5,
          'review': 'Excelente',
          'isAnonymous': true,
          'isReported': false,
          'isActive': true,
          'createdAt': '2026-09-01T10:00:00.000Z',
        },
        {
          'id': 2,
          'referenceId': 'r-2',
          'userId': 10,
          'professionalId': 20,
          'type': 'CLIENT_TO_PROFESSIONAL',
          'rating': 4,
          'review': 'Muy bueno',
          'isAnonymous': false,
          'isReported': false,
          'isActive': true,
          'createdAt': '2026-09-01T10:00:00.000Z',
        },
      ];

      final ratings = jsonList.map(Rating.fromJson).toList();

      expect(ratings, hasLength(2));
      expect(ratings[0].userId, isNull);
      expect(ratings[1].userId, 10);
    });

    test(
      'parsea los campos que el fromJson generado agregó al migrar a codegen (M-04): '
      'serviceId, criteria, isReported, reportReason, createdBy',
      () {
        final json = {
          'id': 3,
          'referenceId': 'r-3',
          'userId': 10,
          'professionalId': 20,
          'serviceId': 'service-uuid-1',
          'type': 'CLIENT_TO_PROFESSIONAL',
          'rating': 3,
          'review': 'Regular',
          'criteria': {'puntualidad': 3, 'calidad': 4},
          'isAnonymous': false,
          'isReported': true,
          'reportReason': 'lenguaje inapropiado',
          'isActive': true,
          'createdAt': '2026-09-01T10:00:00.000Z',
          'createdBy': 'user-uuid-1',
        };

        final rating = Rating.fromJson(json);

        expect(rating.serviceId, 'service-uuid-1');
        expect(rating.criteria, {'puntualidad': 3, 'calidad': 4});
        expect(rating.isReported, isTrue);
        expect(rating.reportReason, 'lenguaje inapropiado');
        expect(rating.createdBy, 'user-uuid-1');
      },
    );

    test(
      'los campos nullable ausentes del JSON (no solo en null explícito) parsean a null',
      () {
        final json = {
          'id': 4,
          'referenceId': 'r-4',
          'userId': 1,
          'professionalId': 2,
          'type': 'CLIENT_TO_PROFESSIONAL',
          'rating': 5,
          'review': 'Excelente',
          'isAnonymous': false,
          'isReported': false,
          'isActive': true,
          'createdAt': '2026-09-01T10:00:00.000Z',
          // serviceId, criteria, reportReason, createdBy: ausentes a propósito.
        };

        final rating = Rating.fromJson(json);

        expect(rating.serviceId, isNull);
        expect(rating.criteria, isNull);
        expect(rating.reportReason, isNull);
        expect(rating.createdBy, isNull);
      },
    );
  });
}
