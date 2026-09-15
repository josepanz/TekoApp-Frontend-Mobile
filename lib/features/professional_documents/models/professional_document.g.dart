// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "ProfessionalDocumentResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'professional_document.dart';

ProfessionalDocument _$ProfessionalDocumentFromJson(
        Map<String, dynamic> json) =>
    ProfessionalDocument(
      referenceId: json['referenceId'] as String,
      professionalDocumentType: ProfessionalDocumentType.fromJson(
          json['professionalDocumentType'] as Map<String, dynamic>),
      fileKey: json['fileKey'] as String?,
      status: DocumentReviewStatus.fromJson(json['status'] as String),
      issuedAt: json['issuedAt'] == null
          ? null
          : DateTime.parse(json['issuedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
