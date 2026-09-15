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
    'images': <String>[],
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
          'id': 10,
          'referenceId': 'client-uuid-1',
          'firstName': 'Juan',
          'lastName': 'Pérez',
          'email': 'juan@example.com',
          'phoneNumber': '+595981234567',
        },
      );

      // Act
      final service = Service.fromJson(json);

      // Assert
      expect(service.client.referenceId, 'client-uuid-1');
      expect(service.client.firstName, 'Juan');
      expect(service.client.id, 10);
      expect(service.client.email, 'juan@example.com');
      expect(service.client.phoneNumber, '+595981234567');
    });

    test(
      'phoneNumber ausente del JSON (no solo null explícito) parsea a null',
      () {
        // Arrange
        final json = _baseServiceJson(
          users: {
            'id': 10,
            'referenceId': 'client-uuid-1',
            'firstName': 'Juan',
            'lastName': 'Pérez',
            'email': 'juan@example.com',
          },
        );

        // Act
        final service = Service.fromJson(json);

        // Assert
        expect(service.client.phoneNumber, isNull);
      },
    );

    test(
      'lanza si el backend no anida "users" — ServiceDetailResponseDTO.users es requerido, '
      'nunca null (ver M-04)',
      () {
        // Arrange
        final json = _baseServiceJson();

        // Act & Assert
        expect(() => Service.fromJson(json), throwsA(anything));
      },
    );
  });
}
