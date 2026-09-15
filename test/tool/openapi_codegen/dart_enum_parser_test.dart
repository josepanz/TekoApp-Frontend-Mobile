// Tests de `tool/openapi_codegen/src/dart_enum_parser.dart` — cubre las 2 formas reales de
// `fromJson` que aparecen en `lib/features/**/models/*.dart` (switch expression en un factory,
// switch statement clásico en un método static), el caso real de línea partida por `dart format`
// (`ContractStatus.pendingProfessionalSignature`), catch-all que relanza vs que absorbe en
// silencio, y el caso `null` cuando no hay `fromJson` para ese enum.
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/openapi_codegen/src/dart_enum_parser.dart';

void main() {
  group('parseEnumFromJson', () {
    test(
      'switch expression (factory) — extrae los literales y detecta el throw',
      () {
        const source = '''
enum PaymentMethodType {
  cash,
  creditCard;

  factory PaymentMethodType.fromJson(String value) {
    return switch (value) {
      'CASH' => PaymentMethodType.cash,
      'CREDIT_CARD' => PaymentMethodType.creditCard,
      _ => throw ArgumentError('PaymentMethodType desconocido: \$value'),
    };
  }
}
''';
        final result = parseEnumFromJson(source, 'PaymentMethodType');

        expect(result, isNotNull);
        expect(result!.recognizedValues, {'CASH', 'CREDIT_CARD'});
        expect(result.throwsOnUnknown, isTrue);
      },
    );

    test(
      'switch statement clásico (static) — extrae los literales y detecta el throw',
      () {
        const source = '''
enum LegalDocumentType {
  termsOfService,
  privacyPolicy;

  static LegalDocumentType fromJson(String value) {
    switch (value) {
      case 'TERMS_OF_SERVICE':
        return LegalDocumentType.termsOfService;
      case 'PRIVACY_POLICY':
        return LegalDocumentType.privacyPolicy;
      default:
        throw ArgumentError('LegalDocumentType desconocido: \$value');
    }
  }
}
''';
        final result = parseEnumFromJson(source, 'LegalDocumentType');

        expect(result, isNotNull);
        expect(result!.recognizedValues, {
          'TERMS_OF_SERVICE',
          'PRIVACY_POLICY',
        });
        expect(result.throwsOnUnknown, isTrue);
      },
    );

    test(
      'caso real: LegalDocumentType con 4 valores contra 6 del schema deja 2 sin cubrir',
      () {
        const source = '''
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
        throw ArgumentError('LegalDocumentType desconocido: \$value');
    }
  }
}
''';
        final result = parseEnumFromJson(source, 'LegalDocumentType')!;
        const schemaValues = {
          'TERMS_OF_SERVICE',
          'PRIVACY_POLICY',
          'DATA_PROCESSING_CONSENT',
          'IMAGE_USAGE_CONSENT',
          'SERVICE_CONTRACT_TERMS',
          'USER_CONTENT_LIABILITY_DISCLAIMER',
        };

        expect(result.recognizedValues, hasLength(4));
        expect(
          schemaValues.difference(result.recognizedValues),
          {'SERVICE_CONTRACT_TERMS', 'USER_CONTENT_LIABILITY_DISCLAIMER'},
        );
      },
    );

    test(
      'tolera el caso real de un case largo partido en 2 líneas por dart format '
      '(ContractStatus.pendingProfessionalSignature)',
      () {
        const source = '''
enum ContractStatus {
  draft,
  pendingProfessionalSignature;

  factory ContractStatus.fromJson(String value) {
    return switch (value) {
      'DRAFT' => ContractStatus.draft,
      'PENDING_PROFESSIONAL_SIGNATURE' =>
        ContractStatus.pendingProfessionalSignature,
      _ => throw ArgumentError('ContractStatus desconocido: \$value'),
    };
  }
}
''';
        final result = parseEnumFromJson(source, 'ContractStatus');

        expect(result, isNotNull);
        expect(
          result!.recognizedValues,
          {'DRAFT', 'PENDING_PROFESSIONAL_SIGNATURE'},
        );
      },
    );

    test(
      'catch-all silencioso (sin throw) — throwsOnUnknown da false, mismo caso real de '
      'AiDisclosureSource',
      () {
        const source = '''
enum AiDisclosureSource {
  platformAi,
  userDeclaredAi;

  static AiDisclosureSource fromJson(String value) {
    switch (value) {
      case 'PLATFORM_AI':
        return AiDisclosureSource.platformAi;
      case 'USER_DECLARED_AI':
        return AiDisclosureSource.userDeclaredAi;
      default:
        return AiDisclosureSource.userDeclaredAi;
    }
  }
}
''';
        final result = parseEnumFromJson(source, 'AiDisclosureSource');

        expect(result, isNotNull);
        expect(result!.throwsOnUnknown, isFalse);
        expect(result.recognizedValues, {'PLATFORM_AI', 'USER_DECLARED_AI'});
      },
    );

    test(
      'no confunde el mensaje de ArgumentError (minúscula/mixta) con un literal de enum',
      () {
        const source = '''
enum Foo {
  bar;

  factory Foo.fromJson(String value) {
    return switch (value) {
      'BAR' => Foo.bar,
      _ => throw ArgumentError('Foo desconocido: \$value'),
    };
  }
}
''';
        final result = parseEnumFromJson(source, 'Foo')!;
        expect(result.recognizedValues, {'BAR'});
      },
    );

    test('devuelve null si el enum no tiene fromJson (ej. DeviceType)', () {
      const source = '''
enum DeviceType {
  ios,
  android;

  String toJson() {
    return switch (this) {
      DeviceType.ios => 'IOS',
      DeviceType.android => 'ANDROID',
    };
  }
}
''';
      expect(parseEnumFromJson(source, 'DeviceType'), isNull);
    });

    test(
      'no cruza el fromJson de OTRO enum del mismo archivo (2 enums, 1 archivo)',
      () {
        const source = '''
enum PaymentMethodType {
  cash;
  factory PaymentMethodType.fromJson(String value) {
    return switch (value) {
      'CASH' => PaymentMethodType.cash,
      _ => throw ArgumentError('x'),
    };
  }
}

enum PaymentProviderType {
  stripe;
  factory PaymentProviderType.fromJson(String value) {
    return switch (value) {
      'STRIPE' => PaymentProviderType.stripe,
      _ => throw ArgumentError('y'),
    };
  }
}
''';
        final methodType = parseEnumFromJson(source, 'PaymentMethodType')!;
        final providerType = parseEnumFromJson(source, 'PaymentProviderType')!;
        expect(methodType.recognizedValues, {'CASH'});
        expect(providerType.recognizedValues, {'STRIPE'});
      },
    );
  });
}
