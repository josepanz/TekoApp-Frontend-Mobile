import 'document_review_status.dart';
import 'professional_document_type.dart';

part 'professional_document.g.dart';

/// `ProfessionalDocumentResponseDTO` — un documento cargado por un profesional.
///
/// `fromJson` generado por `dart run tool/openapi_codegen/generate_model.dart` (M-04, ver
/// `openspec/changes/platform-hardening-2026-09/CODEGEN.md`) — regenerar con:
/// ```
/// dart run tool/openapi_codegen/generate_model.dart \
///   --schema ProfessionalDocumentResponseDTO --class ProfessionalDocument \
///   --openapi-url <backend>/tekoapp-backend/api/swagger-json \
///   --out lib/features/professional_documents/models/professional_document.g.dart \
///   --part professional_document.dart \
///   --enum-fields status:DocumentReviewStatus \
///   --ref-fields professionalDocumentType:ProfessionalDocumentType
/// ```
class ProfessionalDocument {
  const ProfessionalDocument({
    required this.referenceId,
    required this.professionalDocumentType,
    required this.status,
    required this.createdAt,
    this.fileKey,
    this.issuedAt,
    this.expiresAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String referenceId;
  final ProfessionalDocumentType professionalDocumentType;

  /// Key de S3 — resolver la URL presignada vía `GET /uploads/presigned-url` antes de mostrarla,
  /// mismo criterio que las fotos de bitácora (`service_progress`). **`null` si la cuenta del
  /// profesional fue anonimizada (I-01)**: el objeto real se borra de S3, la fila se conserva
  /// como registro de que existió una verificación — el modelo a mano lo casteaba a `String` no
  /// nullable hasta esta migración a codegen (M-04), un drift real introducido por el propio
  /// I-01 de esta sesión (ver `ProfessionalDocumentResponseDTO.fileKey` en el backend). Ningún
  /// consumidor podía crashear con esto todavía (la anonimización recién se implementó), pero el
  /// tipo ya estaba mal desde que el backend cambió el contrato.
  final String? fileKey;
  final DocumentReviewStatus status;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  factory ProfessionalDocument.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalDocumentFromJson(json);
}
