import 'document_review_status.dart';
import 'professional_document_type.dart';

/// `ProfessionalDocumentResponseDTO` — un documento cargado por un profesional.
class ProfessionalDocument {
  const ProfessionalDocument({
    required this.referenceId,
    required this.professionalDocumentType,
    required this.fileKey,
    required this.status,
    required this.createdAt,
    this.issuedAt,
    this.expiresAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String referenceId;
  final ProfessionalDocumentType professionalDocumentType;

  /// Key de S3 — resolver la URL presignada vía `GET /uploads/presigned-url` antes de mostrarla,
  /// mismo criterio que las fotos de bitácora (`service_progress`).
  final String fileKey;
  final DocumentReviewStatus status;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  factory ProfessionalDocument.fromJson(Map<String, dynamic> json) {
    return ProfessionalDocument(
      referenceId: json['referenceId'] as String,
      professionalDocumentType: ProfessionalDocumentType.fromJson(
        json['professionalDocumentType'] as Map<String, dynamic>,
      ),
      fileKey: json['fileKey'] as String,
      status: DocumentReviewStatus.fromJson(json['status'] as String),
      issuedAt: _parseDate(json['issuedAt']),
      expiresAt: _parseDate(json['expiresAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}
