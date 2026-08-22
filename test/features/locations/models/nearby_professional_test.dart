import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/locations/models/nearby_professional.dart';

void main() {
  group('NearbyProfessional.fromJson', () {
    test('parsea la respuesta ya normalizada de GET /locations/nearby', () {
      // Arrange
      final json = {
        'id': 1,
        'referenceId': 'prof-ref-1',
        'categoryId': 3,
        'description': 'Plomero',
        'hourlyRate': 50000,
        'latitude': -25.2637,
        'longitude': -57.5759,
        'distanceKm': 2.34,
        'isOnline': true,
        'averageRating': 4.5,
      };

      // Act
      final professional = NearbyProfessional.fromJson(json);

      // Assert
      expect(professional.id, 1);
      expect(professional.referenceId, 'prof-ref-1');
      expect(professional.latitude, -25.2637);
      expect(professional.longitude, -57.5759);
      expect(professional.distanceKm, 2.34);
    });
  });

  group('copyWithPosition', () {
    test('reemplaza latitud y longitud sin tocar el resto de los campos', () {
      // Arrange
      const professional = NearbyProfessional(
        id: 1,
        referenceId: 'prof-ref-1',
        categoryId: 3,
        description: 'Plomero',
        hourlyRate: 50000,
        latitude: -25.2637,
        longitude: -57.5759,
        distanceKm: 2.34,
        isOnline: true,
        averageRating: 4.5,
      );

      // Act
      final moved = professional.copyWithPosition(
        latitude: -25.3,
        longitude: -57.6,
      );

      // Assert
      expect(moved.latitude, -25.3);
      expect(moved.longitude, -57.6);
      expect(moved.id, professional.id);
      expect(moved.description, professional.description);
    });
  });
}
