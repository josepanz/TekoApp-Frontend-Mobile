import 'document_category.dart';

part 'professional_document_type.g.dart';

/// `ProfessionalDocumentTypeResponseDTO` — una entrada del catálogo parametrizable (antecedente,
/// título, certificado, portafolio).
///
/// `fromJson` generado por `dart run tool/openapi_codegen/generate_model.dart` (M-04, ver
/// `openspec/changes/platform-hardening-2026-09/CODEGEN.md`) — regenerar con:
/// ```
/// dart run tool/openapi_codegen/generate_model.dart \
///   --schema ProfessionalDocumentTypeResponseDTO --class ProfessionalDocumentType \
///   --openapi-url <backend>/tekoapp-backend/api/swagger-json \
///   --out lib/features/professional_documents/models/professional_document_type.g.dart \
///   --part professional_document_type.dart \
///   --int-fields sortOrder,countryId,professionalCategoryId,validityDays \
///   --enum-fields category:DocumentCategory
/// ```
class ProfessionalDocumentType {
  const ProfessionalDocumentType({
    required this.referenceId,
    required this.code,
    required this.name,
    required this.category,
    required this.isRequired,
    required this.requiresStaffReview,
    required this.isVisibleToClient,
    required this.sortOrder,
    required this.isActive,
    this.description,
    this.countryId,
    this.professionalCategoryId,
    this.validityDays,
  });

  final String referenceId;
  final String code;
  final String name;
  final String? description;
  final DocumentCategory category;

  /// El backend lo devuelve siempre (`ProfessionalDocumentTypeResponseDTO.countryId`), pero el
  /// modelo a mano lo descartaba en silencio hasta esta migración a codegen (ver M-04) — sin
  /// consumidor todavía en la UI, se expone igual que hizo B-01/M-05 con hallazgos similares.
  final int? countryId;

  /// Mismo hallazgo que `countryId` — el catálogo puede estar acotado a una categoría de
  /// profesional específica; se descartaba en silencio.
  final int? professionalCategoryId;
  final bool isRequired;

  /// `null` = no vence.
  final int? validityDays;
  final bool requiresStaffReview;
  final bool isVisibleToClient;
  final int sortOrder;
  final bool isActive;

  factory ProfessionalDocumentType.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalDocumentTypeFromJson(json);
}
