import '../../../l10n/app_localizations.dart';
import '../models/legal_document_type.dart';

String legalDocumentTypeLabel(AppLocalizations l10n, LegalDocumentType type) {
  return switch (type) {
    LegalDocumentType.termsOfService => l10n.legalDocumentTypeTermsOfService,
    LegalDocumentType.privacyPolicy => l10n.legalDocumentTypePrivacyPolicy,
    LegalDocumentType.dataProcessingConsent =>
      l10n.legalDocumentTypeDataProcessingConsent,
    LegalDocumentType.imageUsageConsent =>
      l10n.legalDocumentTypeImageUsageConsent,
  };
}
