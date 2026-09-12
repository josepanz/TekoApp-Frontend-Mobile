// Motor de comparación del verificador de drift (`dart run tool/openapi_codegen/check_drift.dart`,
// ver openspec/changes/platform-hardening-2026-09/CODEGEN.md). Compara un modelo Dart TAL COMO
// ESTÁ EN EL REPO — escrito a mano o generado, no hace ninguna diferencia acá — contra el schema
// real de OpenAPI que le corresponde según `model_mapping.dart`.
//
// Reusa `schema_utils.dart` (mismo `refNameOf`/`arrayItemsOf` que ya usa `model_generator.dart`)
// para no duplicar la resolución de `$ref`/`allOf`/arrays, y `dart_model_parser.dart` para leer
// los campos del lado Dart. Separado del CLI (`check_drift.dart`) por el mismo motivo que
// `model_generator.dart` está separado de `generate_model.dart`: para que los tests lo importen
// directo, sin I/O de archivo/red.

import '../model_mapping.dart';
import 'dart_model_parser.dart';
import 'schema_utils.dart';

/// Clasificación gruesa de la FORMA de un campo — no el tipo Dart exacto. Deliberadamente coarse:
/// el schema de OpenAPI no distingue `int` de `double` (ver limitación documentada en
/// `model_generator.dart`), y el mapeo modelo↔schema de este verificador no declara por-campo si
/// un `string` es en realidad un enum Dart o si un `$ref` singular usa tal o cual nombre de clase
/// — exigir esa precisión llevaría a falsos positivos constantes sobre modelos sanos. Ver
/// "Cómo interpretar un reporte de drift" en CODEGEN.md.
enum FieldCategory {
  string,
  datetime,
  number,
  boolean,
  object,
  ref,
  enumString,
  arrayString,
  arrayNumber,
  arrayRef,
  arrayObject,
  arrayOther,

  /// Un tipo Dart con nombre propio que no es ninguno de los tipos "de biblioteca" de arriba
  /// (`String`/`int`/`double`/`num`/`bool`/`DateTime`/`Map`/`List`) — candidato a ser un enum o una
  /// clase anidada. No se valida CUÁL clase puntual, solo que "hay algo tipado ahí".
  custom,

  /// El schema no encaja en ninguna categoría reconocida (tipo de OpenAPI no soportado).
  unknown,
}

/// Categorías del lado del schema (OpenAPI) que un campo del lado Dart puede satisfacer sin que
/// se reporte como discrepancia de tipo. Coarse a propósito — ver docstring de [FieldCategory].
const Map<FieldCategory, Set<FieldCategory>> _compatibleDartCategories = {
  FieldCategory.string: {FieldCategory.string, FieldCategory.custom},
  FieldCategory.datetime: {FieldCategory.datetime},
  FieldCategory.number: {FieldCategory.number},
  FieldCategory.boolean: {FieldCategory.boolean},
  FieldCategory.object: {FieldCategory.object, FieldCategory.custom},
  FieldCategory.ref: {FieldCategory.custom, FieldCategory.object},
  FieldCategory.enumString: {FieldCategory.string, FieldCategory.custom},
  FieldCategory.arrayString: {FieldCategory.arrayString},
  FieldCategory.arrayNumber: {FieldCategory.arrayNumber},
  FieldCategory.arrayRef: {FieldCategory.arrayRef, FieldCategory.arrayObject},
  FieldCategory.arrayObject: {
    FieldCategory.arrayObject,
    FieldCategory.arrayRef,
  },
  FieldCategory.arrayOther: {},
  FieldCategory.unknown: {},
};

FieldCategory schemaCategoryOf(Map<String, dynamic> schema) {
  if (refNameOf(schema) != null) return FieldCategory.ref;

  final items = arrayItemsOf(schema);
  if (items != null) {
    if (refNameOf(items) != null) return FieldCategory.arrayRef;
    switch (items['type']) {
      case 'string':
        return FieldCategory.arrayString;
      case 'number':
        return FieldCategory.arrayNumber;
      case 'object':
        return FieldCategory.arrayObject;
      default:
        return FieldCategory.arrayOther;
    }
  }

  final type = schema['type'] as String?;
  switch (type) {
    case 'string':
      if (schema['format'] == 'date-time') return FieldCategory.datetime;
      if (schema['enum'] != null) return FieldCategory.enumString;
      return FieldCategory.string;
    case 'boolean':
      return FieldCategory.boolean;
    case 'number':
      return FieldCategory.number;
    case 'object':
      return FieldCategory.object;
    default:
      return FieldCategory.unknown;
  }
}

FieldCategory dartCategoryOf(String declaredType) {
  switch (declaredType) {
    case 'String':
      return FieldCategory.string;
    case 'DateTime':
      return FieldCategory.datetime;
    case 'int':
    case 'double':
    case 'num':
      return FieldCategory.number;
    case 'bool':
      return FieldCategory.boolean;
  }
  if (declaredType.startsWith('Map<')) return FieldCategory.object;
  if (declaredType.startsWith('List<')) {
    final inner =
        declaredType.substring('List<'.length, declaredType.length - 1).trim();
    switch (inner) {
      case 'String':
        return FieldCategory.arrayString;
      case 'int':
      case 'double':
      case 'num':
        return FieldCategory.arrayNumber;
    }
    if (inner.startsWith('Map<')) return FieldCategory.arrayObject;
    return FieldCategory.arrayRef;
  }
  return FieldCategory.custom;
}

bool categoriesCompatible(
  FieldCategory schemaCategory,
  FieldCategory dartCategory,
) {
  return _compatibleDartCategories[schemaCategory]?.contains(dartCategory) ??
      false;
}

enum DriftKind {
  /// El schema tiene un campo que el modelo Dart no declara — el patrón de B-01/M-05: el backend
  /// lo devuelve siempre y el modelo lo descarta en silencio.
  missingInModel,

  /// El modelo Dart declara un campo que ya no está en el schema — puede ser un campo que el
  /// backend dejó de exponer, o un nombre que nunca coincidió (ver `--rename-fields`/renameFields
  /// en `model_mapping.dart`).
  extraInModel,

  /// La forma del campo no coincide (ej. el schema dice array y el modelo un escalar).
  typeMismatch,

  /// El caso que motivó todo esto (`fileKey`): el schema declara el campo nullable pero el
  /// modelo lo castea como no-nullable (crashea en runtime), o al revés (el modelo es más
  /// defensivo de lo que hace falta).
  nullabilityMismatch,

  /// `model_mapping.dart` referencia un `schemaName` que no existe en el documento OpenAPI
  /// cargado (nombre mal escrito, o el backend lo renombró/eliminó).
  schemaNotFound,

  /// `model_mapping.dart` referencia un archivo/clase que ya no existe en el repo.
  modelNotFound,

  /// Un archivo bajo `lib/features/*/models/` declara una clase/enum que no está ni mapeada a un
  /// schema ni exenta con motivo — cierra la brecha de "un modelo nuevo se olvidó de registrar".
  unregisteredModel,
}

enum Severity { critical, warn }

class DriftFinding {
  const DriftFinding({
    required this.className,
    required this.schemaName,
    required this.field,
    required this.kind,
    required this.severity,
    this.expected,
    this.found,
  });

  final String className;
  final String schemaName;
  final String field;
  final DriftKind kind;
  final Severity severity;
  final String? expected;
  final String? found;

  String describe() {
    final where = '$className.$field (schema: $schemaName)';
    switch (kind) {
      case DriftKind.missingInModel:
        return '[FALTA EN MODELO] $where — el schema lo declara ($expected) y el modelo Dart '
            'no lo lee. Drift real: el backend puede estar mandando un campo que la app '
            'ignora en silencio.';
      case DriftKind.extraInModel:
        return '[SOBRA EN MODELO] $where — el modelo Dart declara "$field" ($found) pero el '
            'schema no lo tiene. Puede ser un campo que el backend eliminó, o un nombre que '
            'nunca coincidió con la clave JSON real (ver renameFields).';
      case DriftKind.typeMismatch:
        return '[TIPO] $where — el schema espera $expected, el modelo declara $found.';
      case DriftKind.nullabilityMismatch:
        return '[NULABILIDAD] $where — el schema espera $expected, el modelo declara $found.';
      case DriftKind.schemaNotFound:
        return '[SCHEMA NO ENCONTRADO] $className -> "$schemaName" no está en '
            'components.schemas del documento OpenAPI cargado.';
      case DriftKind.modelNotFound:
        return '[MODELO NO ENCONTRADO] $expected';
      case DriftKind.unregisteredModel:
        return '[SIN REGISTRAR] $className en $expected — ni mapeado a un schema ni exento '
            'con motivo en model_mapping.dart.';
    }
  }
}

String _describeSchemaField(Map<String, dynamic> schema, bool nullable) {
  final category = schemaCategoryOf(schema);
  return '${category.name}${nullable ? '?' : ''}';
}

/// Compara UN mapeo modelo↔schema. `dartSource` es el contenido del archivo `.dart` (ya leído por
/// el llamador) donde vive `mapping.className`.
List<DriftFinding> checkMapping({
  required ModelMapping mapping,
  required Map<String, dynamic> schemas,
  required String dartSource,
}) {
  final schema = schemas[mapping.schemaName] as Map<String, dynamic>?;
  if (schema == null) {
    return [
      DriftFinding(
        className: mapping.className,
        schemaName: mapping.schemaName,
        field: '-',
        kind: DriftKind.schemaNotFound,
        severity: Severity.critical,
      ),
    ];
  }

  final properties =
      (schema['properties'] as Map<String, dynamic>?) ?? const {};
  final required =
      ((schema['required'] as List?) ?? const []).cast<String>().toSet();

  final ignoredSchemaFields = {
    for (final e in mapping.schemaFieldExemptions) e.field,
  };
  final ignoredModelFields = {
    for (final e in mapping.modelFieldExemptions) e.field,
  };

  final List<DartModelField> parsedFields;
  try {
    parsedFields = parseDartFields(dartSource, mapping.className);
  } on StateError catch (e) {
    return [
      DriftFinding(
        className: mapping.className,
        schemaName: mapping.schemaName,
        field: '-',
        kind: DriftKind.modelNotFound,
        severity: Severity.critical,
        expected: e.message,
      ),
    ];
  }
  final modelFields = {for (final f in parsedFields) f.name: f};

  final findings = <DriftFinding>[];
  final matchedModelFieldNames = <String>{};

  for (final entry in properties.entries) {
    final schemaFieldName = entry.key;
    if (ignoredSchemaFields.contains(schemaFieldName)) continue;

    final propSchema = entry.value as Map<String, dynamic>;
    final schemaNullable =
        propSchema['nullable'] == true || !required.contains(schemaFieldName);
    final dartFieldName =
        mapping.renameFields[schemaFieldName] ?? schemaFieldName;
    final modelField = modelFields[dartFieldName];

    if (modelField == null) {
      findings.add(
        DriftFinding(
          className: mapping.className,
          schemaName: mapping.schemaName,
          field: schemaFieldName,
          kind: DriftKind.missingInModel,
          severity: Severity.critical,
          expected: _describeSchemaField(propSchema, schemaNullable),
        ),
      );
      continue;
    }
    matchedModelFieldNames.add(dartFieldName);

    final schemaCategory = schemaCategoryOf(propSchema);
    final dartCategory = dartCategoryOf(modelField.declaredType);
    if (!categoriesCompatible(schemaCategory, dartCategory)) {
      findings.add(
        DriftFinding(
          className: mapping.className,
          schemaName: mapping.schemaName,
          field: schemaFieldName,
          kind: DriftKind.typeMismatch,
          severity: Severity.critical,
          expected: _describeSchemaField(propSchema, schemaNullable),
          found: modelField.toString(),
        ),
      );
    }

    if (schemaNullable && !modelField.nullable) {
      findings.add(
        DriftFinding(
          className: mapping.className,
          schemaName: mapping.schemaName,
          field: schemaFieldName,
          kind: DriftKind.nullabilityMismatch,
          // El caso fileKey: el backend puede mandar null y el modelo lo castea no-nullable ->
          // crashea en runtime. Máxima severidad.
          severity: Severity.critical,
          expected:
              'nullable (${_describeSchemaField(propSchema, schemaNullable)})',
          found: 'no nullable (${modelField.declaredType})',
        ),
      );
    } else if (!schemaNullable && modelField.nullable) {
      findings.add(
        DriftFinding(
          className: mapping.className,
          schemaName: mapping.schemaName,
          field: schemaFieldName,
          kind: DriftKind.nullabilityMismatch,
          // El modelo es más defensivo de lo necesario — no crashea, no es urgente.
          severity: Severity.warn,
          expected:
              'no nullable (${_describeSchemaField(propSchema, schemaNullable)})',
          found: 'nullable (${modelField.declaredType}?)',
        ),
      );
    }
  }

  for (final field in modelFields.values) {
    if (matchedModelFieldNames.contains(field.name)) continue;
    if (ignoredModelFields.contains(field.name)) continue;
    findings.add(
      DriftFinding(
        className: mapping.className,
        schemaName: mapping.schemaName,
        field: field.name,
        kind: DriftKind.extraInModel,
        severity: Severity.warn,
        found: field.toString(),
      ),
    );
  }

  return findings;
}

/// Chequeo de cobertura: toda clase/enum/mixin declarado en `modelFileSources` (archivo -> código
/// fuente) debe estar mapeado a un schema (`mappings`) o exento con motivo (`exemptions`) — sea a
/// nivel de archivo completo (`LocalModelExemption.className == null`) o de una clase puntual
/// dentro de un archivo que también tiene clases mapeadas.
List<DriftFinding> checkCoverage({
  required List<ModelMapping> mappings,
  required List<LocalModelExemption> exemptions,
  required Map<String, String> modelFileSources,
}) {
  final mappedClasses = {
    for (final m in mappings) '${m.dartFile}::${m.className}',
  };
  final wholeFileExemptions = {
    for (final e in exemptions)
      if (e.className == null) e.dartFile,
  };
  final classExemptions = {
    for (final e in exemptions)
      if (e.className != null) '${e.dartFile}::${e.className}',
  };

  final findings = <DriftFinding>[];
  final sortedFiles = modelFileSources.keys.toList()..sort();
  for (final dartFile in sortedFiles) {
    if (wholeFileExemptions.contains(dartFile)) continue;
    final source = modelFileSources[dartFile]!;
    for (final typeName in topLevelTypeNamesIn(source)) {
      final key = '$dartFile::$typeName';
      if (mappedClasses.contains(key) || classExemptions.contains(key)) {
        continue;
      }
      findings.add(
        DriftFinding(
          className: typeName,
          schemaName: '-',
          field: '-',
          kind: DriftKind.unregisteredModel,
          severity: Severity.critical,
          expected: dartFile,
        ),
      );
    }
  }
  return findings;
}
