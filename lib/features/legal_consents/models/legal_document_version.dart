import 'legal_document_type.dart';

class LegalDocumentVersion {
  const LegalDocumentVersion({
    required this.referenceId,
    required this.documentType,
    required this.countryId,
    required this.version,
    required this.contentUrl,
    required this.publishedAt,
    required this.isActive,
  });

  final String referenceId;
  final LegalDocumentType documentType;
  final int? countryId;
  final String version;
  final String contentUrl;
  final DateTime publishedAt;
  final bool isActive;

  factory LegalDocumentVersion.fromJson(Map<String, dynamic> json) {
    return LegalDocumentVersion(
      referenceId: json['referenceId'] as String,
      documentType: LegalDocumentType.fromJson(json['documentType'] as String),
      countryId: json['countryId'] as int?,
      version: json['version'] as String,
      contentUrl: json['contentUrl'] as String,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      isActive: json['isActive'] as bool,
    );
  }
}
