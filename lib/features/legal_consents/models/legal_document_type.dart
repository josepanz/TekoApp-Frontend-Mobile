/// Espeja `LegalDocumentType` de Prisma (`TekoApp-Backend/prisma/schema.prisma`) — ver
/// `openspec/specs/data-and-media-consent.md`. `serviceContractTerms`/
/// `userContentLiabilityDisclaimer` sumados en M-04 §11.1 (verificador de drift v2, que compara
/// VALORES de enum — el hallazgo real que motivó esa extensión: este enum cubría 4 valores contra
/// los 6 reales del schema). Ninguno de los dos tiene consumidor en la UI todavía
/// (`serviceContractTerms` lo usa el backend al generar el contrato desde una opción de
/// presupuesto, `userContentLiabilityDisclaimer` no gatea ninguna ruta todavía — decisión de
/// producto/legal pendiente, ver `TekoApp-Backend/openspec/decisions.md`).
enum LegalDocumentType {
  termsOfService,
  privacyPolicy,
  dataProcessingConsent,
  imageUsageConsent,
  serviceContractTerms,
  userContentLiabilityDisclaimer;

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
      case 'SERVICE_CONTRACT_TERMS':
        return LegalDocumentType.serviceContractTerms;
      case 'USER_CONTENT_LIABILITY_DISCLAIMER':
        return LegalDocumentType.userContentLiabilityDisclaimer;
      default:
        throw ArgumentError('LegalDocumentType desconocido: $value');
    }
  }
}
