// Cubre el case explícito nuevo `OTHER` (M-04 §11.1, verificador de drift v2): antes se llegaba a
// `AiDisclosureEntityType.other` solo vía el catch-all silencioso, sin un case propio — el
// verificador ahora compara VALORES de enum y lo marcaba como advertencia.
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/ai_disclosure_entity_type.dart';

void main() {
  group('AiDisclosureEntityType.fromJson', () {
    test('reconoce OTHER con un case explícito', () {
      expect(
        AiDisclosureEntityType.fromJson('OTHER'),
        AiDisclosureEntityType.other,
      );
    });

    test(
      'un valor futuro no reconocido sigue absorbiéndose en silencio como other (catch-all '
      'defensivo, no relanza)',
      () {
        expect(
          AiDisclosureEntityType.fromJson('ALGO_NUEVO'),
          AiDisclosureEntityType.other,
        );
      },
    );
  });
}
