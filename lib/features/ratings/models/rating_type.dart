/// `RatingType` — mismo enum del backend (`prisma/schema.prisma`).
enum RatingType {
  clientToProfessional,
  professionalToClient;

  factory RatingType.fromJson(String value) {
    return switch (value) {
      'CLIENT_TO_PROFESSIONAL' => RatingType.clientToProfessional,
      'PROFESSIONAL_TO_CLIENT' => RatingType.professionalToClient,
      _ => throw ArgumentError('RatingType desconocido: $value'),
    };
  }

  String toJson() {
    return switch (this) {
      RatingType.clientToProfessional => 'CLIENT_TO_PROFESSIONAL',
      RatingType.professionalToClient => 'PROFESSIONAL_TO_CLIENT',
    };
  }
}
