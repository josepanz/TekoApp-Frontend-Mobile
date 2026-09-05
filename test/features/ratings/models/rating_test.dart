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
          'isActive': true,
          'createdAt': '2026-09-01T10:00:00.000Z',
        },
      ];

      final ratings = jsonList.map(Rating.fromJson).toList();

      expect(ratings, hasLength(2));
      expect(ratings[0].userId, isNull);
      expect(ratings[1].userId, 10);
    });
  });
}
