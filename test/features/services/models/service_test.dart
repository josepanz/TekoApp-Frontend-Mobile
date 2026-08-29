import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/services/models/service.dart';

Map<String, dynamic> _baseServiceJson({Map<String, dynamic>? users}) {
  return {
    'id': 1,
    'referenceId': 'svc-uuid-1',
    'userId': 1,
    'professionalId': 2,
    'categoryId': 3,
    'serviceTypeId': 4,
    'title': 'Reparación',
    'description': 'desc',
    'status': 'COMPLETED',
    'latitude': -25.2,
    'longitude': -57.5,
    'address': 'Av. España 1234',
    'isUrgent': false,
    'createdAt': '2026-08-08T10:00:00.000Z',
    if (users != null) 'users': users,
  };
}

void main() {
  group('Service.client', () {
    test('mapea el cliente desde la clave "users" del backend', () {
      // Arrange
      final json = _baseServiceJson(
        users: {
          'referenceId': 'client-uuid-1',
          'firstName': 'Juan',
          'lastName': 'Pérez',
        },
      );

      // Act
      final service = Service.fromJson(json);

      // Assert
      expect(service.client?.referenceId, 'client-uuid-1');
      expect(service.client?.firstName, 'Juan');
    });

    test('queda en null cuando el backend no anida "users"', () {
      // Arrange
      final json = _baseServiceJson();

      // Act
      final service = Service.fromJson(json);

      // Assert
      expect(service.client, isNull);
    });
  });
}
