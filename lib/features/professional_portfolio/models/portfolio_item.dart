import 'portfolio_review_status.dart';

/// `PortfolioItemResponseDTO` — una foto de trabajos anteriores del portafolio de un profesional.
class PortfolioItem {
  const PortfolioItem({
    required this.referenceId,
    required this.fileKey,
    required this.sortOrder,
    required this.isVisible,
    required this.status,
    required this.createdAt,
    this.caption,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String referenceId;

  /// Key de S3 — resolver la URL presignada vía `GET /uploads/presigned-url` antes de mostrarla.
  final String fileKey;
  final String? caption;
  final int sortOrder;
  final bool isVisible;
  final PortfolioReviewStatus status;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      referenceId: json['referenceId'] as String,
      fileKey: json['fileKey'] as String,
      caption: json['caption'] as String?,
      sortOrder: json['sortOrder'] as int,
      isVisible: json['isVisible'] as bool,
      status: PortfolioReviewStatus.fromJson(json['status'] as String),
      reviewedAt: _parseDate(json['reviewedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}
