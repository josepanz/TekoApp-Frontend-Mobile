// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "ProfessionalDetailResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'professional_profile.dart';

ProfessionalProfile _$ProfessionalProfileFromJson(Map<String, dynamic> json) =>
    ProfessionalProfile(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      userId: json['userId'] as int,
      categoryId: json['categoryId'] as int,
      description: json['description'] as String,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      fixedRate: (json['fixedRate'] as num?)?.toDouble(),
      skills: (json['skills'] as List<dynamic>).cast<String>(),
      certifications: (json['certifications'] as List<dynamic>).cast<String>(),
      yearsOfExperience: json['yearsOfExperience'] as int,
      status: ProfessionalStatus.fromJson(json['status'] as String),
      isAvailable: json['isAvailable'] as bool,
      isOnline: json['isOnline'] as bool,
      verificationStatus: json['verificationStatus'] as String,
      requiredDocumentsVerified: json['requiredDocumentsVerified'] as bool,
      currentLatitude: (json['currentLatitude'] as num?)?.toDouble(),
      currentLongitude: (json['currentLongitude'] as num?)?.toDouble(),
      lastLocationUpdate: json['lastLocationUpdate'] == null
          ? null
          : DateTime.parse(json['lastLocationUpdate'] as String),
      totalServices: json['totalServices'] as int,
      averageRating: (json['averageRating'] as num).toDouble(),
      totalRatings: json['totalRatings'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: ProfessionalUserSummary.fromJson(
          json['user'] as Map<String, dynamic>),
      category: ProfessionalCategorySummary.fromJson(
          json['category'] as Map<String, dynamic>),
    );
