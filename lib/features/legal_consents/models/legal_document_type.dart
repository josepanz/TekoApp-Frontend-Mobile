/// Espeja `LegalDocumentType` de Prisma (`TekoApp-Backend/prisma/schema.prisma`) — ver
/// `openspec/specs/data-and-media-consent.md`.
enum LegalDocumentType {
  termsOfService,
  privacyPolicy,
  dataProcessingConsent,
  imageUsageConsent;

  static LegalDocumentType fromJson(String value) {
    switch (value) {
      case 'TERMS_OF_SERVICE':
        return LegalDocumentType.termsOfService;
      case 'PRIVACY_POLICY':
        return LegalDocumentType.privacyPolicy;
      case 'DATA_PROCESSING_CONSENT':
        return LegalDocumentType.dataProcessingConsent;
      case 'IMAGE_USAGE_CONSENT':
        return LegalDocumentType.imageUsageConsent;
      default:
        throw ArgumentError('LegalDocumentType desconocido: $value');
    }
  }
}
