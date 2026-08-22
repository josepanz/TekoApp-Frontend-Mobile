/// Un profesional devuelto por `GET /locations/nearby` — ya normalizado por el backend
/// (ver `NearbyProfessionalResponseDTO`, fix aplicado en la misma fase).
class NearbyProfessional {
  const NearbyProfessional({
    required this.id,
    required this.referenceId,
    required this.categoryId,
    required this.description,
    required this.hourlyRate,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.isOnline,
    required this.averageRating,
  });

  final int id;
  final String referenceId;
  final int categoryId;
  final String description;
  final double hourlyRate;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final bool isOnline;
  final double averageRating;

  factory NearbyProfessional.fromJson(Map<String, dynamic> json) {
    return NearbyProfessional(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      categoryId: json['categoryId'] as int,
      description: json['description'] as String,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      isOnline: json['isOnline'] as bool,
      averageRating: (json['averageRating'] as num).toDouble(),
    );
  }

  NearbyProfessional copyWithPosition({
    required double latitude,
    required double longitude,
  }) {
    return NearbyProfessional(
      id: id,
      referenceId: referenceId,
      categoryId: categoryId,
      description: description,
      hourlyRate: hourlyRate,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distanceKm,
      isOnline: isOnline,
      averageRating: averageRating,
    );
  }
}
