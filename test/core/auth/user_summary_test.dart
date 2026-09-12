import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';

void main() {
  Map<String, dynamic> baseJson({Object? deletionScheduledAt = 'absent'}) => {
        'id': 'ref-1',
        'email': 'a@b.com',
        'firstName': 'Ana',
        'lastName': 'Pérez',
        'phoneNumber': null,
        'avatarUrl': null,
        if (deletionScheduledAt != 'absent')
          'deletionScheduledAt': deletionScheduledAt,
      };

  group('UserSummary.fromJson', () {
    test('deletionScheduledAt es null cuando el campo no viaja (ausente)', () {
      final user = UserSummary.fromJson(baseJson());
      expect(user.deletionScheduledAt, isNull);
    });

    test('deletionScheduledAt es null cuando el backend lo manda null', () {
      final user = UserSummary.fromJson(
        baseJson(deletionScheduledAt: null),
      );
      expect(user.deletionScheduledAt, isNull);
    });

    test(
      'deletionScheduledAt se parsea a DateTime cuando hay una solicitud activa',
      () {
        final user = UserSummary.fromJson(
          baseJson(deletionScheduledAt: '2026-09-25T10:00:00.000Z'),
        );
        expect(
          user.deletionScheduledAt,
          DateTime.parse('2026-09-25T10:00:00.000Z'),
        );
      },
    );
  });
}
