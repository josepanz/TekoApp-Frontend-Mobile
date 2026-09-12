// Tests de `tool/openapi_codegen/src/drift_checker.dart` — el motor de comparación de
// `check_drift.dart`. Cubre cada clase de drift que puede reportar (campo faltante, campo sobrante,
// discrepancia de tipo, discrepancia de nulabilidad en ambas direcciones, schema/modelo no
// encontrado, exenciones, renombres) y confirma que NO da falsos positivos sobre la forma real de
// `RatingDetailResponseDTO`/`Rating` (un modelo que ya sabemos sano, ver
// `test/tool/openapi_codegen/model_generator_test.dart` y CODEGEN.md §7).
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/openapi_codegen/model_mapping.dart';
import '../../../tool/openapi_codegen/src/drift_checker.dart';

void main() {
  group('categorías de campo', () {
    test('number del schema es compatible con int y con double del modelo', () {
      expect(
        categoriesCompatible(FieldCategory.number, FieldCategory.number),
        isTrue,
      );
      expect(dartCategoryOf('int'), FieldCategory.number);
      expect(dartCategoryOf('double'), FieldCategory.number);
    });

    test(r'un $ref del schema es compatible con un tipo custom o un Map', () {
      final schema = {r'$ref': '#/components/schemas/TipResponseDTO'};
      expect(schemaCategoryOf(schema), FieldCategory.ref);
      expect(
        categoriesCompatible(FieldCategory.ref, FieldCategory.custom),
        isTrue,
      );
      expect(
        categoriesCompatible(FieldCategory.ref, FieldCategory.object),
        isTrue,
      );
      expect(
        categoriesCompatible(FieldCategory.ref, FieldCategory.string),
        isFalse,
      );
    });

    test(r'array de $ref es compatible con List<ClaseCustom>', () {
      final schema = {
        'type': 'array',
        'items': {r'$ref': '#/components/schemas/ContractLineItemSnapshotDTO'},
      };
      expect(schemaCategoryOf(schema), FieldCategory.arrayRef);
      expect(
        dartCategoryOf('List<ContractLineItemSnapshot>'),
        FieldCategory.arrayRef,
      );
      expect(
        categoriesCompatible(FieldCategory.arrayRef, FieldCategory.arrayRef),
        isTrue,
      );
    });

    test('boolean del schema NO es compatible con String del modelo', () {
      expect(
        categoriesCompatible(FieldCategory.boolean, FieldCategory.string),
        isFalse,
      );
    });
  });

  group('checkMapping — sin falsos positivos sobre un modelo sano', () {
    test('Rating vs RatingDetailResponseDTO no reporta drift', () {
      final schemas = {
        'RatingDetailResponseDTO': {
          'type': 'object',
          'properties': {
            'id': {'type': 'number'},
            'referenceId': {'type': 'string'},
            'userId': {'type': 'number'},
            'type': {
              'type': 'string',
              'enum': ['CLIENT_TO_PROFESSIONAL', 'PROFESSIONAL_TO_CLIENT'],
            },
            'rating': {'type': 'number'},
            'review': {'type': 'string'},
            'criteria': {'type': 'object'},
            'isActive': {'type': 'boolean'},
            'createdAt': {'type': 'string', 'format': 'date-time'},
          },
          'required': [
            'id',
            'referenceId',
            'type',
            'rating',
            'isActive',
            'createdAt',
          ],
        },
      };

      const source = '''
class Rating {
  const Rating({
    required this.id,
    required this.referenceId,
    required this.type,
    required this.rating,
    required this.isActive,
    required this.createdAt,
    this.userId,
    this.review,
    this.criteria,
  });

  final int id;
  final String referenceId;
  final int? userId;
  final RatingType type;
  final double rating;
  final String? review;
  final Map<String, dynamic>? criteria;
  final bool isActive;
  final DateTime createdAt;
}
''';

      final findings = checkMapping(
        mapping: const ModelMapping(
          dartFile: 'lib/features/ratings/models/rating.dart',
          className: 'Rating',
          schemaName: 'RatingDetailResponseDTO',
        ),
        schemas: schemas,
        dartSource: source,
      );

      expect(findings, isEmpty);
    });
  });

  group('checkMapping — detecta cada clase de drift', () {
    Map<String, dynamic> schemaWith(
      Map<String, dynamic> properties,
      List<String> required,
    ) {
      return {
        'FakeDTO': {
          'type': 'object',
          'properties': properties,
          'required': required,
        },
      };
    }

    test('campo del schema ausente en el modelo (patrón B-01/M-05)', () {
      final schemas = schemaWith({
        'code': {'type': 'string'},
        'discountPercentage': {'type': 'number'},
      }, [
        'code',
      ]);
      const source = '''
class Fake {
  const Fake({required this.code});
  final String code;
}
''';
      final findings = checkMapping(
        mapping: const ModelMapping(
          dartFile: 'fake.dart',
          className: 'Fake',
          schemaName: 'FakeDTO',
        ),
        schemas: schemas,
        dartSource: source,
      );

      expect(findings, hasLength(1));
      expect(findings.single.kind, DriftKind.missingInModel);
      expect(findings.single.field, 'discountPercentage');
      expect(findings.single.severity, Severity.critical);
    });

    test('campo del modelo ausente en el schema', () {
      final schemas = schemaWith({
        'code': {'type': 'string'},
      }, [
        'code',
      ]);
      const source = '''
class Fake {
  const Fake({required this.code, required this.legacyField});
  final String code;
  final String legacyField;
}
''';
      final findings = checkMapping(
        mapping: const ModelMapping(
          dartFile: 'fake.dart',
          className: 'Fake',
          schemaName: 'FakeDTO',
        ),
        schemas: schemas,
        dartSource: source,
      );

      expect(findings, hasLength(1));
      expect(findings.single.kind, DriftKind.extraInModel);
      expect(findings.single.field, 'legacyField');
      expect(findings.single.severity, Severity.warn);
    });

    test('discrepancia de tipo (schema array, modelo escalar)', () {
      final schemas = schemaWith({
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      }, [
        'tags',
      ]);
      const source = '''
class Fake {
  const Fake({required this.tags});
  final String tags;
}
''';
      final findings = checkMapping(
        mapping: const ModelMapping(
          dartFile: 'fake.dart',
          className: 'Fake',
          schemaName: 'FakeDTO',
        ),
        schemas: schemas,
        dartSource: source,
      );

      expect(findings, hasLength(1));
      expect(findings.single.kind, DriftKind.typeMismatch);
    });

    test(
      'nulabilidad: schema nullable pero modelo no-nullable es CRÍTICO (caso fileKey)',
      () {
        final schemas = schemaWith({
          'fileKey': {'type': 'string', 'nullable': true},
        }, [
          'fileKey',
        ]);
        const source = '''
class Fake {
  const Fake({required this.fileKey});
  final String fileKey;
}
''';
        final findings = checkMapping(
          mapping: const ModelMapping(
            dartFile: 'fake.dart',
            className: 'Fake',
            schemaName: 'FakeDTO',
          ),
          schemas: schemas,
          dartSource: source,
        );

        expect(findings, hasLength(1));
        expect(findings.single.kind, DriftKind.nullabilityMismatch);
        expect(findings.single.severity, Severity.critical);
      },
    );

    test(
      'nulabilidad: schema no-nullable pero modelo nullable es ADVERTENCIA (defensivo de más)',
      () {
        final schemas = schemaWith({
          'code': {'type': 'string'},
        }, [
          'code',
        ]);
        const source = '''
class Fake {
  const Fake({this.code});
  final String? code;
}
''';
        final findings = checkMapping(
          mapping: const ModelMapping(
            dartFile: 'fake.dart',
            className: 'Fake',
            schemaName: 'FakeDTO',
          ),
          schemas: schemas,
          dartSource: source,
        );

        expect(findings, hasLength(1));
        expect(findings.single.kind, DriftKind.nullabilityMismatch);
        expect(findings.single.severity, Severity.warn);
      },
    );

    test('schema no encontrado en el documento OpenAPI', () {
      final findings = checkMapping(
        mapping: const ModelMapping(
          dartFile: 'fake.dart',
          className: 'Fake',
          schemaName: 'NoExiste',
        ),
        schemas: const {},
        dartSource: 'class Fake { const Fake(); }',
      );

      expect(findings, hasLength(1));
      expect(findings.single.kind, DriftKind.schemaNotFound);
    });

    test('clase no encontrada en el archivo Dart', () {
      final schemas = schemaWith({
        'code': {'type': 'string'},
      }, [
        'code',
      ]);
      final findings = checkMapping(
        mapping: const ModelMapping(
          dartFile: 'fake.dart',
          className: 'NoExiste',
          schemaName: 'FakeDTO',
        ),
        schemas: schemas,
        dartSource: 'class Fake { const Fake(); }',
      );

      expect(findings, hasLength(1));
      expect(findings.single.kind, DriftKind.modelNotFound);
    });
  });

  group('renameFields', () {
    test('un campo renombrado no se reporta como faltante ni como sobrante',
        () {
      final schemas = {
        'ServiceDetailResponseDTO': {
          'type': 'object',
          'properties': {
            'users': {
              r'$ref': '#/components/schemas/ServiceUserSummaryResponseDTO',
            },
          },
          'required': ['users'],
        },
      };
      const source = '''
class Service {
  const Service({required this.client});
  final ServiceClientSummary client;
}
''';
      final findings = checkMapping(
        mapping: const ModelMapping(
          dartFile: 'fake.dart',
          className: 'Service',
          schemaName: 'ServiceDetailResponseDTO',
          renameFields: {'users': 'client'},
        ),
        schemas: schemas,
        dartSource: source,
      );

      expect(findings, isEmpty);
    });
  });

  group('exenciones', () {
    test('un campo del schema exento no se reporta como faltante', () {
      final schemas = {
        'LoginUserResponseDTO': {
          'type': 'object',
          'properties': {
            'login': {'type': 'boolean'},
            'refreshToken': {'type': 'string', 'nullable': true},
          },
          'required': ['login'],
        },
      };
      const source = '''
class LoginResult {
  const LoginResult({required this.login});
  final bool login;
}
''';
      final findings = checkMapping(
        mapping: ModelMapping(
          dartFile: 'fake.dart',
          className: 'LoginResult',
          schemaName: 'LoginUserResponseDTO',
          schemaFieldExemptions: [
            FieldExemption(
              field: 'refreshToken',
              reason: 'nunca viaja en el body, solo cookie httpOnly.',
            ),
          ],
        ),
        schemas: schemas,
        dartSource: source,
      );

      expect(findings, isEmpty);
    });

    test('un campo del modelo exento no se reporta como sobrante', () {
      final schemas = {
        'FakeDTO': {
          'type': 'object',
          'properties': {
            'code': {'type': 'string'},
          },
          'required': ['code'],
        },
      };
      const source = '''
class Fake {
  const Fake({required this.code, required this.localOnly});
  final String code;
  final String localOnly;
}
''';
      final findings = checkMapping(
        mapping: ModelMapping(
          dartFile: 'fake.dart',
          className: 'Fake',
          schemaName: 'FakeDTO',
          modelFieldExemptions: [
            FieldExemption(
              field: 'localOnly',
              reason: 'campo derivado en el cliente, no viene del backend.',
            ),
          ],
        ),
        schemas: schemas,
        dartSource: source,
      );

      expect(findings, isEmpty);
    });

    test('FieldExemption sin motivo real tira ArgumentError', () {
      expect(
        () => FieldExemption(field: 'x', reason: ''),
        throwsArgumentError,
      );
      expect(
        () => FieldExemption(field: 'x', reason: 'no'),
        throwsArgumentError,
      );
    });

    test('LocalModelExemption sin motivo real tira ArgumentError', () {
      expect(
        () => LocalModelExemption(dartFile: 'fake.dart', reason: ''),
        throwsArgumentError,
      );
    });
  });

  group('checkCoverage', () {
    test('una clase sin mapear ni exenta se reporta como SIN REGISTRAR', () {
      final findings = checkCoverage(
        mappings: const [],
        exemptions: const [],
        modelFileSources: {
          'lib/features/foo/models/foo.dart': 'class Foo { const Foo(); }',
        },
      );

      expect(findings, hasLength(1));
      expect(findings.single.kind, DriftKind.unregisteredModel);
      expect(findings.single.className, 'Foo');
    });

    test('una exención de archivo completo cubre todas sus clases/enums', () {
      final findings = checkCoverage(
        mappings: const [],
        exemptions: [
          LocalModelExemption(
            dartFile: 'lib/features/foo/models/foo_failure.dart',
            reason: 'jerarquía de errores de dominio, sin schema propio.',
          ),
        ],
        modelFileSources: {
          'lib/features/foo/models/foo_failure.dart': '''
sealed class FooFailure implements Exception {}
class FooConflictFailure extends FooFailure {}
''',
        },
      );

      expect(findings, isEmpty);
    });

    test(
        'una exención de una clase puntual no cubre las demás del mismo archivo',
        () {
      final findings = checkCoverage(
        mappings: const [
          ModelMapping(
            dartFile: 'lib/features/foo/models/foo.dart',
            className: 'FooMapped',
            schemaName: 'FooDTO',
          ),
        ],
        exemptions: [
          LocalModelExemption(
            dartFile: 'lib/features/foo/models/foo.dart',
            className: 'FooLocalOnly',
            reason: 'estado local de UI, sin contraparte en el backend.',
          ),
        ],
        modelFileSources: {
          'lib/features/foo/models/foo.dart': '''
class FooMapped { const FooMapped(); }
class FooLocalOnly { const FooLocalOnly(); }
class FooForgotten { const FooForgotten(); }
''',
        },
      );

      expect(findings, hasLength(1));
      expect(findings.single.className, 'FooForgotten');
    });
  });
}
