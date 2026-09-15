/// Última posición conocida de un profesional — `GET /locations/professional/:id`
/// (`ProfessionalLocationResponseDTO` en el backend).
class ProfessionalLastLocation {
  const ProfessionalLastLocation({
    required this.latitude,
    required this.longitude,
    this.lastUpdate,
  });

  final double latitude;
  final double longitude;

  /// Última vez que mutó la coordenada, según el backend. `null` en las instancias que arma
  /// `assigned_professional_location_provider.dart` a partir de un evento del socket
  /// (`locationUpdated` no manda esta marca de tiempo, solo lat/lng) — no tiene consumidor en la
  /// UI todavía, se expone para que quede disponible cuando alguna pantalla lo necesite (mismo
  /// criterio que `ratings`/`professional_profile` en M-04).
  final DateTime? lastUpdate;

  factory ProfessionalLastLocation.fromJson(Map<String, dynamic> json) {
    return ProfessionalLastLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      lastUpdate: json['lastUpdate'] == null
          ? null
          : DateTime.parse(json['lastUpdate'] as String),
    );
  }
}
