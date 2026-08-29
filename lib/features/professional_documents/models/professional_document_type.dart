import 'document_category.dart';

/// `ProfessionalDocumentTypeResponseDTO` — una entrada del catálogo parametrizable (antecedente,
/// título, certificado, portafolio).
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
    this.validityDays,
  });

  final String referenceId;
  final String code;
  final String name;
  final String? description;
  final DocumentCategory category;
  final bool isRequired;

  /// `null` = no vence.
  final int? validityDays;
  final bool requiresStaffReview;
  final bool isVisibleToClient;
  final int sortOrder;
  final bool isActive;

  factory ProfessionalDocumentType.fromJson(Map<String, dynamic> json) {
    return ProfessionalDocumentType(
      referenceId: json['referenceId'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: DocumentCategory.fromJson(json['category'] as String),
      isRequired: json['isRequired'] as bool,
      validityDays: json['validityDays'] as int?,
      requiresStaffReview: json['requiresStaffReview'] as bool,
      isVisibleToClient: json['isVisibleToClient'] as bool,
      sortOrder: json['sortOrder'] as int,
      isActive: json['isActive'] as bool,
    );
  }
}
