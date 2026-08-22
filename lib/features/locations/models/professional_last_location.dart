/// Última posición conocida de un profesional — `GET /locations/professional/:id`
/// (`ProfessionalLocationResponseDTO` en el backend).
class ProfessionalLastLocation {
  const ProfessionalLastLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  factory ProfessionalLastLocation.fromJson(Map<String, dynamic> json) {
    return ProfessionalLastLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
