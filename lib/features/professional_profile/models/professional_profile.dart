import 'professional_status.dart';

part 'professional_profile.g.dart';

/// Usuario dueño del perfil profesional, tal cual lo anida `ProfessionalDetailResponseDTO.user` —
/// no es el mismo modelo que otro dominio use para "usuario", cada dominio anida su propia forma
/// resumida (mismo criterio que `ServiceCategorySummary` en `features/services/models/service.dart`).
class ProfessionalUserSummary {
  const ProfessionalUserSummary({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;

  factory ProfessionalUserSummary.fromJson(Map<String, dynamic> json) {
    return ProfessionalUserSummary(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}

/// Categoría del profesional tal cual la anida `ProfessionalDetailResponseDTO.category`.
class ProfessionalCategorySummary {
  const ProfessionalCategorySummary({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
  });

  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;

  factory ProfessionalCategorySummary.fromJson(Map<String, dynamic> json) {
    return ProfessionalCategorySummary(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }
}

/// `Professionals` — a diferencia de `Service`/`ServiceRequest`, esta tabla SÍ expone `id` (Int) y
/// `referenceId` (UUID) por separado (ver `openspec/decisions.md`). Se conserva `categoryId` (Int)
/// porque `GET /services?categoryId=` (disponibles para mi categoría, Paso 7) lo necesita como
/// query param.
///
/// `fromJson` está generado desde el schema real de `ProfessionalDetailResponseDTO` (ver M-04,
/// `tool/openapi_codegen/generate_model.dart` y `professional_profile.g.dart`) — validado contra
/// `--openapi-url` de un backend corriendo. Migrarlo expuso que el modelo a mano descartaba en
/// silencio `userId`, `certifications`, `verificationStatus`, `requiredDocumentsVerified`,
/// `currentLatitude`/`currentLongitude`/`lastLocationUpdate`, `totalServices`, `averageRating`,
/// `totalRatings`, `createdAt`, `user` y `category` (mismo patrón que B-01/M-05) — `userId` es el
/// hallazgo más notable: el modelo nunca lo expuso pese a que el DTO lo devuelve siempre. También
/// `yearsOfExperience`/`skills` se trataban como opcionales cuando el backend los devuelve
/// siempre. Ninguno de los campos nuevos tiene consumidor en la UI todavía — expuestos para que
/// la próxima pantalla que los necesite no tenga que volver a tocar el modelo primero.
class ProfessionalProfile {
  const ProfessionalProfile({
    required this.id,
    required this.referenceId,
    required this.userId,
    required this.categoryId,
    required this.description,
    required this.hourlyRate,
    required this.skills,
    required this.certifications,
    required this.yearsOfExperience,
    required this.status,
    required this.isAvailable,
    required this.isOnline,
    required this.verificationStatus,
    required this.requiredDocumentsVerified,
    required this.totalServices,
    required this.averageRating,
    required this.totalRatings,
    required this.createdAt,
    required this.user,
    required this.category,
    this.fixedRate,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
  });

  final int id;
  final String referenceId;

  /// Int interno crudo del usuario dueño del perfil — el backend siempre lo devuelve. Sin
  /// consumidor en la UI todavía.
  final int userId;
  final int categoryId;
  final String description;
  final double hourlyRate;
  final double? fixedRate;
  final List<String> skills;

  /// Sin consumidor en la UI todavía.
  final List<String> certifications;
  final int yearsOfExperience;
  final ProfessionalStatus status;
  final bool isAvailable;
  final bool isOnline;

  /// `'UNVERIFIED' | 'VERIFIED' | 'REJECTED'` — aprobación manual de staff sobre la cuenta,
  /// distinto de [requiredDocumentsVerified]. Sin consumidor en la UI todavía.
  final String verificationStatus;

  /// Derivado por el backend: todos los documentos obligatorios (antecedentes/habilitación)
  /// están aprobados y sin vencer. Sin consumidor en la UI todavía.
  final bool requiredDocumentsVerified;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;

  /// Sin consumidor en la UI todavía.
  final int totalServices;

  /// Sin consumidor en la UI todavía — distinto de las stats que ya expone
  /// `ProfessionalRatingStatsResponseDTO`.
  final double averageRating;

  /// Sin consumidor en la UI todavía.
  final int totalRatings;
  final DateTime createdAt;
  final ProfessionalUserSummary user;
  final ProfessionalCategorySummary category;

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalProfileFromJson(json);
}
