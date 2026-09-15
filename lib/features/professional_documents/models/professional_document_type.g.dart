// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "ProfessionalDocumentTypeResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'professional_document_type.dart';

ProfessionalDocumentType _$ProfessionalDocumentTypeFromJson(
        Map<String, dynamic> json) =>
    ProfessionalDocumentType(
      referenceId: json['referenceId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: DocumentCategory.fromJson(json['category'] as String),
      countryId: json['countryId'] as int?,
      professionalCategoryId: json['professionalCategoryId'] as int?,
      isRequired: json['isRequired'] as bool,
      validityDays: json['validityDays'] as int?,
      requiresStaffReview: json['requiresStaffReview'] as bool,
      isVisibleToClient: json['isVisibleToClient'] as bool,
      sortOrder: json['sortOrder'] as int,
      isActive: json['isActive'] as bool,
    );
