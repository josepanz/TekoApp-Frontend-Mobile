import 'ai_disclosure_entity_type.dart';
import 'content_usage_scope.dart';

class ContentConsentGrant {
  const ContentConsentGrant({
    required this.referenceId,
    required this.contentType,
    required this.contentReferenceId,
    required this.usageScope,
    required this.grantedAt,
    required this.revokedAt,
  });

  final String referenceId;
  final AiDisclosureEntityType contentType;
  final String contentReferenceId;
  final ContentUsageScope usageScope;
  final DateTime grantedAt;
  final DateTime? revokedAt;

  bool get isActive => revokedAt == null;

  factory ContentConsentGrant.fromJson(Map<String, dynamic> json) {
    return ContentConsentGrant(
      referenceId: json['referenceId'] as String,
      contentType: AiDisclosureEntityType.fromJson(
        json['contentType'] as String,
      ),
      contentReferenceId: json['contentReferenceId'] as String,
      usageScope: ContentUsageScope.fromJson(json['usageScope'] as String),
      grantedAt: DateTime.parse(json['grantedAt'] as String),
      revokedAt: json['revokedAt'] == null
          ? null
          : DateTime.parse(json['revokedAt'] as String),
    );
  }
}
