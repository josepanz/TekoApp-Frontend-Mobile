// Cubre los 2 valores nuevos sumados junto con el verificador de drift v2 (M-04 §11.1):
// `SERVICE_CONTRACT_TERMS`/`USER_CONTENT_LIABILITY_DISCLAIMER`, que el schema real ya declaraba
// pero este enum no reconocía — ver openspec/changes/platform-hardening-2026-09/CODEGEN.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_document_type.dart';

void main() {
  group('LegalDocumentType.fromJson', () {
    test('reconoce los 6 valores reales del schema', () {
      expect(
        LegalDocumentType.fromJson('TERMS_OF_SERVICE'),
        LegalDocumentType.termsOfService,
      );
      expect(
        LegalDocumentType.fromJson('PRIVACY_POLICY'),
        LegalDocumentType.privacyPolicy,
      );
      expect(
        LegalDocumentType.fromJson('DATA_PROCESSING_CONSENT'),
        LegalDocumentType.dataProcessingConsent,
      );
      expect(
        LegalDocumentType.fromJson('IMAGE_USAGE_CONSENT'),
        LegalDocumentType.imageUsageConsent,
      );
      expect(
        LegalDocumentType.fromJson('SERVICE_CONTRACT_TERMS'),
        LegalDocumentType.serviceContractTerms,
      );
      expect(
        LegalDocumentType.fromJson('USER_CONTENT_LIABILITY_DISCLAIMER'),
        LegalDocumentType.userContentLiabilityDisclaimer,
      );
    });

    test('sigue relanzando ante un valor desconocido', () {
      expect(
        () => LegalDocumentType.fromJson('ALGO_NUEVO'),
        throwsArgumentError,
      );
    });
  });
}
