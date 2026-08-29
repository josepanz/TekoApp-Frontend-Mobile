import 'legal_document_version.dart';

class UserConsent {
  const UserConsent({
    required this.referenceId,
    required this.acceptedAt,
    required this.legalDocumentVersion,
  });

  final String referenceId;
  final DateTime acceptedAt;
  final LegalDocumentVersion legalDocumentVersion;

  factory UserConsent.fromJson(Map<String, dynamic> json) {
    return UserConsent(
      referenceId: json['referenceId'] as String,
      acceptedAt: DateTime.parse(json['acceptedAt'] as String),
      legalDocumentVersion: LegalDocumentVersion.fromJson(
        json['legalDocumentVersion'] as Map<String, dynamic>,
      ),
    );
  }
}
