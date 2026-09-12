import 'schema_utils.dart';

// Lógica de generación de `generate_model.dart`, separada del script de línea de comandos para
// que `test/tool/openapi_codegen/model_generator_test.dart` pueda importarla directo y ejercitar
// `generateModelSource`/`castExpressionFor` sin pasar por `Process.run` ni por I/O de archivos o
// red. El script (`tool/openapi_codegen/generate_model.dart`) sigue siendo el punto de entrada:
// parsea argumentos, lee el documento OpenAPI (archivo o URL) y delega acá.
//
// Ver `openspec/changes/platform-hardening-2026-09/CODEGEN.md` para el diseño completo y el
// historial de versiones del generador.

/// Opciones de una corrida de generación para UN schema/clase.
class ModelGenOptions {
  ModelGenOptions({
    required this.schemaName,
    required this.className,
    required this.out,
    required this.partOf,
    this.intFields = const {},
    this.enumFields = const {},
    this.refFields = const {},
    this.renameFields = const {},
  });

  final String schemaName;
  final String className;
  final String out;
  final String partOf;
  final Set<String> intFields;
  final Map<String, String> enumFields;

  /// Campo del schema (clave del JSON) → clase Dart que ya tiene su propio
  /// `factory <Clase>.fromJson(Map<String, dynamic> json)` — para objetos anidados vía `$ref`
  /// (directo o envuelto en `allOf`, patrón que usa `@nestjs/swagger` para adjuntar `nullable`
  /// junto a un `$ref`) y para arrays de objetos anidados (`items: {$ref: ...}` → `List<Clase>`,
  /// ver v4). No resuelve el schema referenciado en ningún caso: delega en el `fromJson` que el
  /// dominio ya tiene escrito a mano para esa clase.
  final Map<String, String> refFields;

  /// Clave del JSON → nombre del parámetro Dart, para los pocos campos donde el backend expone
  /// una clave distinta al nombre que el modelo Dart ya usa (p.ej. `Service.users` → `client`,
  /// ver M-04/CODEGEN.md). El acceso a `json['<clave>']` sigue usando la clave del JSON; solo
  /// cambia el nombre del parámetro nombrado que se emite.
  final Map<String, String> renameFields;
}

/// Genera el contenido completo del archivo `.g.dart` (con `part of` y el `_$<Clase>FromJson`)
/// para `schema` según `options`. `schema` es el objeto `components.schemas.<Nombre>` ya
/// decodificado (no el documento OpenAPI completo).
String generateModelSource(
  Map<String, dynamic> schema,
  ModelGenOptions options,
) {
  final properties = schema['properties'] as Map<String, dynamic>;
  final required =
      ((schema['required'] as List?) ?? const []).cast<String>().toSet();

  final buffer = StringBuffer()
    ..writeln(
      '// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde '
      '"${options.schemaName}" — no editar a mano.',
    )
    ..writeln(
      '// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend',
    )
    ..writeln(
      '// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/'
      'platform-hardening-2026-09/CODEGEN.md).',
    )
    ..writeln("part of '${options.partOf}';")
    ..writeln()
    ..writeln(
      '${options.className} _\$${options.className}FromJson(Map<String, dynamic> json) =>',
    )
    ..writeln('    ${options.className}(');

  for (final entry in properties.entries) {
    final name = entry.key;
    final propSchema = entry.value as Map<String, dynamic>;
    final nullable = propSchema['nullable'] == true || !required.contains(name);
    final expression = castExpressionFor(
      name: name,
      schema: propSchema,
      nullable: nullable,
      options: options,
    );
    final paramName = options.renameFields[name] ?? name;
    buffer.writeln('      $paramName: $expression,');
  }

  buffer.writeln('    );');
  return buffer.toString();
}

/// Calcula la expresión Dart de casteo/parsing para un campo del schema. Es la única función que
/// hace falta extender cuando un dominio nuevo trae un shape de OpenAPI que todavía no se cubre
/// (ver "Limitaciones conocidas" en CODEGEN.md).
String castExpressionFor({
  required String name,
  required Map<String, dynamic> schema,
  required bool nullable,
  required ModelGenOptions options,
}) {
  final type = schema['type'] as String?;
  final format = schema['format'] as String?;
  final enumTarget = options.enumFields[name];
  final refTarget = options.refFields[name];
  final suffix = nullable ? '?' : '';
  final access = "json['$name']";

  if (type == 'array') {
    final items = arrayItemsOf(schema);
    final itemsRef = items != null ? refNameOf(items) : null;
    if (itemsRef != null) {
      // v4: array de objetos anidados (`items: {$ref: ...}`) — el mismo mapa `--ref-fields` que
      // ya resuelve un objeto anidado singular ahora también resuelve el elemento de un array,
      // delegando en el `fromJson` que la clase Dart del elemento ya tiene escrito a mano. No
      // resuelve el schema referenciado (igual que el `$ref` singular): si el dominio necesita
      // que ESE elemento también se genere, se lo migra aparte con su propia corrida del
      // generador (mismo patrón que `Contract`/`ContractContentSnapshot`/`ContractLineItemSnapshot`
      // en el dominio `contracts`).
      if (refTarget == null) {
        throw UnsupportedError(
          'Array de objetos anidados para "$name" (items \$ref a "$itemsRef") '
          'necesita --ref-fields $name:<ClaseDart> — el elemento del array delega en el '
          '`fromJson` que esa clase ya tiene escrito a mano.',
        );
      }
      final elementExpr = '$refTarget.fromJson(e as Map<String, dynamic>)';
      if (nullable) {
        return '($access as List<dynamic>?)?.map((e) => $elementExpr).toList()';
      }
      return '($access as List<dynamic>).map((e) => $elementExpr).toList()';
    }

    final itemsType = items?['type'];
    if (itemsType == 'string') {
      if (nullable) {
        return '($access as List<dynamic>?)?.cast<String>()';
      }
      return '($access as List<dynamic>).cast<String>()';
    }
    if (itemsType == 'number') {
      // Mismo criterio que el escalar: sin `format: int32` en el schema, `--int-fields` decide
      // si cada elemento es `int` o `double` (ver "Limitaciones conocidas" en CODEGEN.md sobre
      // `int` vs `double`).
      final elementCast = options.intFields.contains(name)
          ? '(e as num).toInt()'
          : '(e as num).toDouble()';
      if (nullable) {
        return '($access as List<dynamic>?)?.map((e) => $elementCast).toList()';
      }
      return '($access as List<dynamic>).map((e) => $elementCast).toList()';
    }
    throw UnsupportedError(
      'Array de items "$itemsType" no soportado para "$name" — solo '
      'arrays de string/number/objetos vía \$ref. Extendé castExpressionFor en '
      'tool/openapi_codegen/src/model_generator.dart.',
    );
  }

  if (refTarget != null) {
    if (nullable) {
      return '$access == null ? null : $refTarget.fromJson('
          '$access as Map<String, dynamic>)';
    }
    return '$refTarget.fromJson($access as Map<String, dynamic>)';
  }

  if (enumTarget != null) {
    if (nullable) {
      return '$access == null ? null : $enumTarget.fromJson($access as String)';
    }
    return '$enumTarget.fromJson($access as String)';
  }

  if (type == 'string' && format == 'date-time') {
    if (nullable) {
      return '$access == null ? null : DateTime.parse($access as String)';
    }
    return 'DateTime.parse($access as String)';
  }

  if (type == 'string') {
    return '$access as String$suffix';
  }

  if (type == 'boolean') {
    return '$access as bool$suffix';
  }

  if (type == 'number') {
    if (options.intFields.contains(name)) {
      return '$access as int$suffix';
    }
    return '($access as num$suffix)${nullable ? '?' : ''}.toDouble()';
  }

  if (type == 'object') {
    // v1: objeto libre sin `additionalProperties` tipado — ver el comentario de cabecera de
    // `generate_model.dart`.
    return '$access as Map<String, dynamic>$suffix';
  }

  throw UnsupportedError(
    'Tipo de schema no soportado para "$name": $schema. '
    'Extendé castExpressionFor en tool/openapi_codegen/src/model_generator.dart.',
  );
}
