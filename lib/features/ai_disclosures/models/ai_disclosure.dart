import '../../legal_consents/models/ai_disclosure_entity_type.dart';
import 'ai_disclosure_source.dart';

/// Espeja `AiContentDisclosures` (`TekoApp-Backend/openspec/specs/ai-content-disclosure.md`).
class AiDisclosure {
  const AiDisclosure({
    required this.referenceId,
    required this.entityType,
    required this.entityReferenceId,
    required this.source,
    this.aiProvider,
    this.declaredByUserId,
    this.note,
    required this.createdAt,
  });

  final String referenceId;
  final AiDisclosureEntityType entityType;
  final String entityReferenceId;
  final AiDisclosureSource source;
  final String? aiProvider;
  final int? declaredByUserId;
  final String? note;
  final DateTime createdAt;

  factory AiDisclosure.fromJson(Map<String, dynamic> json) {
    return AiDisclosure(
      referenceId: json['referenceId'] as String,
      entityType: AiDisclosureEntityType.fromJson(
        json['entityType'] as String,
      ),
      entityReferenceId: json['entityReferenceId'] as String,
      source: AiDisclosureSource.fromJson(json['source'] as String),
      aiProvider: json['aiProvider'] as String?,
      declaredByUserId: json['declaredByUserId'] as int?,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
