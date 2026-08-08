import 'professional_status.dart';

/// `Professionals` — a diferencia de `Service`/`ServiceRequest`, esta tabla SÍ expone `id` (Int) y
/// `referenceId` (UUID) por separado (ver `openspec/decisions.md`). Se conserva `categoryId` (Int)
/// porque `GET /services?categoryId=` (disponibles para mi categoría, Paso 7) lo necesita como
/// query param.
class ProfessionalProfile {
  const ProfessionalProfile({
    required this.id,
    required this.referenceId,
    required this.categoryId,
    required this.description,
    required this.hourlyRate,
    required this.status,
    required this.isAvailable,
    required this.isOnline,
    this.fixedRate,
    this.skills = const [],
    this.yearsOfExperience,
  });

  final int id;
  final String referenceId;
  final int categoryId;
  final String description;
  final double hourlyRate;
  final double? fixedRate;
  final List<String> skills;
  final int? yearsOfExperience;
  final ProfessionalStatus status;
  final bool isAvailable;
  final bool isOnline;

  factory ProfessionalProfile.fromJson(Map<String, dynamic> json) {
    return ProfessionalProfile(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      categoryId: json['categoryId'] as int,
      description: json['description'] as String,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      fixedRate: (json['fixedRate'] as num?)?.toDouble(),
      skills: (json['skills'] as List<dynamic>? ?? const []).cast<String>(),
      yearsOfExperience: json['yearsOfExperience'] as int?,
      status: ProfessionalStatus.fromJson(json['status'] as String),
      isAvailable: json['isAvailable'] as bool,
      isOnline: json['isOnline'] as bool,
    );
  }
}
