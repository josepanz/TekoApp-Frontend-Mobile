import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/realtime/locations_socket_service.dart';

void main() {
  group('ProfessionalLocationUpdate.fromJson', () {
    test('parsea el payload de locationUpdated del backend', () {
      // Arrange
      final json = {
        'professionalId': 42,
        'location': {
          'latitude': -25.2637,
          'longitude': -57.5759,
          'timestamp': '2026-08-09T00:00:00.000Z',
        },
      };

      // Act
      final update = ProfessionalLocationUpdate.fromJson(json);

      // Assert
      expect(update.professionalId, 42);
      expect(update.latitude, -25.2637);
      expect(update.longitude, -57.5759);
    });
  });
}
