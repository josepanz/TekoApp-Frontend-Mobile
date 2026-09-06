// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "RatingDetailResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'rating.dart';

Rating _$RatingFromJson(Map<String, dynamic> json) => Rating(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      userId: json['userId'] as int?,
      professionalId: json['professionalId'] as int?,
      serviceId: json['serviceId'] as String?,
      type: RatingType.fromJson(json['type'] as String),
      rating: (json['rating'] as num).toDouble(),
      review: json['review'] as String?,
      criteria: json['criteria'] as Map<String, dynamic>?,
      isAnonymous: json['isAnonymous'] as bool,
      isReported: json['isReported'] as bool,
      reportReason: json['reportReason'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String?,
    );
