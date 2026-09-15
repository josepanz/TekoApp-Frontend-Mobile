// Tests del generador de modelos (`tool/openapi_codegen/src/model_generator.dart`), no del
// generador CLI en sí — importan la lógica directo (sin `Process.run`, sin I/O de archivo/red)
// para poder cubrir cada shape de OpenAPI con un caso puntual. Ver
// openspec/changes/platform-hardening-2026-09/CODEGEN.md, "Sin tests unitarios propios todavía"
// (§5) — esta migración de `contracts` los agrega por primera vez.
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/openapi_codegen/src/model_generator.dart';

void main() {
  ModelGenOptions options({
    Set<String> intFields = const {},
    Map<String, String> enumFields = const {},
    Map<String, String> refFields = const {},
    Map<String, String> renameFields = const {},
  }) {
    return ModelGenOptions(
      schemaName: 'FakeDTO',
      className: 'Fake',
      out: 'fake.g.dart',
      partOf: 'fake.dart',
      intFields: intFields,
      enumFields: enumFields,
      refFields: refFields,
      renameFields: renameFields,
    );
  }

  group('castExpressionFor — escalares', () {
    test('string requerido castea sin `?`', () {
      final expr = castExpressionFor(
        name: 'title',
        schema: const {'type': 'string'},
        nullable: false,
        options: options(),
      );

      expect(expr, "json['title'] as String");
    });

    test('string opcional castea con `?`', () {
      final expr = castExpressionFor(
        name: 'title',
        schema: const {'type': 'string'},
        nullable: true,
        options: options(),
      );

      expect(expr, "json['title'] as String?");
    });

    test('string con format date-time no nullable usa DateTime.parse directo',
        () {
      final expr = castExpressionFor(
        name: 'createdAt',
        schema: const {'type': 'string', 'format': 'date-time'},
        nullable: false,
        options: options(),
      );

      expect(expr, "DateTime.parse(json['createdAt'] as String)");
    });

    test(
        'string con format date-time nullable resguarda el null antes de parsear',
        () {
      final expr = castExpressionFor(
        name: 'signedAt',
        schema: const {'type': 'string', 'format': 'date-time'},
        nullable: true,
        options: options(),
      );

      expect(
        expr,
        "json['signedAt'] == null ? null : DateTime.parse(json['signedAt'] as String)",
      );
    });

    test('boolean requerido', () {
      final expr = castExpressionFor(
        name: 'pdfAvailable',
        schema: const {'type': 'boolean'},
        nullable: false,
        options: options(),
      );

      expect(expr, "json['pdfAvailable'] as bool");
    });

    test('number sin --int-fields castea a double', () {
      final expr = castExpressionFor(
        name: 'totalPrice',
        schema: const {'type': 'number'},
        nullable: false,
        options: options(),
      );

      expect(expr, "(json['totalPrice'] as num).toDouble()");
    });

    test('number en --int-fields castea a int', () {
      final expr = castExpressionFor(
        name: 'count',
        schema: const {'type': 'number'},
        nullable: false,
        options: options(intFields: {'count'}),
      );

      expect(expr, "json['count'] as int");
    });

    test('object libre sin --ref-fields cae a Map<String, dynamic>', () {
      final expr = castExpressionFor(
        name: 'metadata',
        schema: const {'type': 'object'},
        nullable: true,
        options: options(),
      );

      expect(expr, "json['metadata'] as Map<String, dynamic>?");
    });
  });

  group('castExpressionFor — enums y objetos anidados singulares', () {
    test('enum vía --enum-fields, no nullable', () {
      final expr = castExpressionFor(
        name: 'status',
        schema: const {
          'type': 'string',
          'enum': ['DRAFT', 'SIGNED'],
        },
        nullable: false,
        options: options(enumFields: {'status': 'ContractStatus'}),
      );

      expect(expr, "ContractStatus.fromJson(json['status'] as String)");
    });

    test('enum vía --enum-fields, nullable', () {
      final expr = castExpressionFor(
        name: 'status',
        schema: const {
          'type': 'string',
          'enum': ['DRAFT', 'SIGNED'],
        },
        nullable: true,
        options: options(enumFields: {'status': 'ContractStatus'}),
      );

      expect(
        expr,
        "json['status'] == null ? null : ContractStatus.fromJson(json['status'] as String)",
      );
    });

    test('objeto anidado singular vía --ref-fields (\$ref directo), requerido',
        () {
      final expr = castExpressionFor(
        name: 'contentSnapshot',
        schema: const {
          r'$ref': '#/components/schemas/ContractContentSnapshotDTO',
        },
        nullable: false,
        options: options(
          refFields: {'contentSnapshot': 'ContractContentSnapshot'},
        ),
      );

      expect(
        expr,
        "ContractContentSnapshot.fromJson(json['contentSnapshot'] as Map<String, dynamic>)",
      );
    });

    test('objeto anidado singular vía --ref-fields (allOf + nullable)', () {
      final expr = castExpressionFor(
        name: 'legalTermsVersion',
        schema: const {
          'allOf': [
            {r'$ref': '#/components/schemas/LegalTermsVersionSummaryDTO'},
          ],
        },
        nullable: true,
        options: options(
          refFields: {'legalTermsVersion': 'LegalTermsVersionSummary'},
        ),
      );

      expect(
        expr,
        "json['legalTermsVersion'] == null ? null : LegalTermsVersionSummary.fromJson("
        "json['legalTermsVersion'] as Map<String, dynamic>)",
      );
    });
  });

  group('castExpressionFor — arrays', () {
    test('array de string requerido', () {
      final expr = castExpressionFor(
        name: 'tags',
        schema: const {
          'type': 'array',
          'items': {'type': 'string'},
        },
        nullable: false,
        options: options(),
      );

      expect(expr, "(json['tags'] as List<dynamic>).cast<String>()");
    });

    test('array de number sin --int-fields mapea a double', () {
      final expr = castExpressionFor(
        name: 'amounts',
        schema: const {
          'type': 'array',
          'items': {'type': 'number'},
        },
        nullable: false,
        options: options(),
      );

      expect(
        expr,
        "(json['amounts'] as List<dynamic>).map((e) => (e as num).toDouble()).toList()",
      );
    });

    test('array de number en --int-fields mapea a int', () {
      final expr = castExpressionFor(
        name: 'specificUserIds',
        schema: const {
          'type': 'array',
          'items': {'type': 'number'},
        },
        nullable: true,
        options: options(intFields: {'specificUserIds'}),
      );

      expect(
        expr,
        "(json['specificUserIds'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList()",
      );
    });

    test(
      'array de objetos anidados (items \$ref) requerido delega en --ref-fields',
      () {
        final expr = castExpressionFor(
          name: 'lineItems',
          schema: const {
            'type': 'array',
            'items': {
              r'$ref': '#/components/schemas/ContractLineItemSnapshotDTO',
            },
          },
          nullable: false,
          options: options(
            refFields: {'lineItems': 'ContractLineItemSnapshot'},
          ),
        );

        expect(
          expr,
          "(json['lineItems'] as List<dynamic>).map((e) => "
          'ContractLineItemSnapshot.fromJson(e as Map<String, dynamic>)).toList()',
        );
      },
    );

    test('array de objetos anidados nullable delega en --ref-fields', () {
      final expr = castExpressionFor(
        name: 'consents',
        schema: const {
          'type': 'array',
          'items': {r'$ref': '#/components/schemas/UserConsentResponseDTO'},
        },
        nullable: true,
        options: options(refFields: {'consents': 'UserConsent'}),
      );

      expect(
        expr,
        "(json['consents'] as List<dynamic>?)?.map((e) => "
        'UserConsent.fromJson(e as Map<String, dynamic>)).toList()',
      );
    });

    test(
      'array de objetos anidados SIN --ref-fields tira UnsupportedError con mensaje accionable',
      () {
        expect(
          () => castExpressionFor(
            name: 'lineItems',
            schema: const {
              'type': 'array',
              'items': {
                r'$ref': '#/components/schemas/ContractLineItemSnapshotDTO',
              },
            },
            nullable: false,
            options: options(),
          ),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              contains('--ref-fields lineItems:<ClaseDart>'),
            ),
          ),
        );
      },
    );

    test('array de items de tipo no soportado tira UnsupportedError', () {
      expect(
        () => castExpressionFor(
          name: 'weird',
          schema: const {
            'type': 'array',
            'items': {'type': 'boolean'},
          },
          nullable: false,
          options: options(),
        ),
        throwsUnsupportedError,
      );
    });
  });

  test('tipo de schema no soportado tira UnsupportedError', () {
    expect(
      () => castExpressionFor(
        name: 'weird',
        schema: const {'type': 'integer-ish-nonsense'},
        nullable: false,
        options: options(),
      ),
      throwsUnsupportedError,
    );
  });

  group('generateModelSource', () {
    test(
      'genera part-of, firma y delega arrays de objetos anidados — shape de '
      'ContractContentSnapshotDTO',
      () {
        final schema = <String, dynamic>{
          'type': 'object',
          'properties': {
            'service': {
              r'$ref': '#/components/schemas/ContractServiceSnapshotDTO',
            },
            'budgetOption': {
              r'$ref': '#/components/schemas/ContractBudgetOptionSnapshotDTO',
            },
            'lineItems': {
              'type': 'array',
              'items': {
                r'$ref': '#/components/schemas/ContractLineItemSnapshotDTO',
              },
            },
          },
          'required': ['service', 'budgetOption', 'lineItems'],
        };

        final code = generateModelSource(
          schema,
          ModelGenOptions(
            schemaName: 'ContractContentSnapshotDTO',
            className: 'ContractContentSnapshot',
            out: 'contract_content_snapshot.g.dart',
            partOf: 'contract.dart',
            refFields: const {
              'service': 'ContractServiceSnapshot',
              'budgetOption': 'ContractBudgetOptionSnapshot',
              'lineItems': 'ContractLineItemSnapshot',
            },
          ),
        );

        expect(code, contains("part of 'contract.dart';"));
        expect(
          code,
          contains(
            'ContractContentSnapshot _\$ContractContentSnapshotFromJson(Map<String, dynamic> json) =>',
          ),
        );
        expect(
          code,
          contains(
            "service: ContractServiceSnapshot.fromJson(json['service'] as Map<String, dynamic>),",
          ),
        );
        expect(
          code,
          contains(
            "lineItems: (json['lineItems'] as List<dynamic>).map((e) => "
            'ContractLineItemSnapshot.fromJson(e as Map<String, dynamic>)).toList(),',
          ),
        );
      },
    );

    test(
        'respeta --rename-fields para el nombre del parámetro, no de la clave JSON',
        () {
      final schema = <String, dynamic>{
        'type': 'object',
        'properties': {
          'users': {'type': 'string'},
        },
        'required': ['users'],
      };

      final code = generateModelSource(
        schema,
        ModelGenOptions(
          schemaName: 'ServiceDetailResponseDTO',
          className: 'Service',
          out: 'service.g.dart',
          partOf: 'service.dart',
          renameFields: const {'users': 'client'},
        ),
      );

      expect(code, contains("client: json['users'] as String,"));
    });
  });
}
