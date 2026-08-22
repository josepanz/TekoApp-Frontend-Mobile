import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/locations/models/professional_last_location.dart';

void main() {
  group('ProfessionalLastLocation.fromJson', () {
    test('parsea latitud y longitud de GET /locations/professional/:id', () {
      // Arrange
      final json = {'latitude': -25.29, 'longitude': -57.62};

      // Act
      final location = ProfessionalLastLocation.fromJson(json);

      // Assert
      expect(location.latitude, -25.29);
      expect(location.longitude, -57.62);
    });
  });
}
