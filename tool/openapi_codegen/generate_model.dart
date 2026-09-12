// Genera un `<modelo>.g.dart` (`part of`, con el `fromJson`) desde un schema real de
// OpenAPI/swagger — prueba de concepto de M-04, ver
// openspec/changes/platform-hardening-2026-09/CODEGEN.md.
//
// v1: cubre los shapes que aparecen en `RatingDetailResponseDTO` (string, number, boolean,
// enums de string, date-time, objetos libres). No resuelve `$ref` a otros schemas ni arrays de
// objetos — se extiende a medida que un dominio nuevo lo necesite (ver CODEGEN.md, "Cómo
// extender").
//
// v2 (M-04, dominios payments/services/professionals): agrega `--ref-fields` (objeto anidado vía
// `$ref` directo o `allOf: [{$ref}]`, delega en el `fromJson` que la clase Dart ya tiene),
// `--rename-fields` (clave del JSON con un nombre de parámetro Dart distinto, ver
// `Service.users` → `client`) y arrays de `string` (`type: array, items: {type: string}` →
// `List<String>`). Sigue sin resolver arrays de objetos anidados.
//
// v3 (M-04, dominio promotions): agrega arrays de `number` (`type: array, items: {type:
// number}` → `List<int>` si el campo está en `--int-fields`, `List<double>` si no — mismo
// criterio que ya existía para escalares, ver "Limitaciones conocidas" en CODEGEN.md sobre
// `int` vs `double`). Sigue sin resolver arrays de objetos anidados.
//
// Uso (contra el fixture local, sin backend corriendo):
//   dart run tool/openapi_codegen/generate_model.dart \
//     --schema RatingDetailResponseDTO --class Rating \
//     --openapi-file tool/openapi_codegen/fixtures/swagger.local-example.json \
//     --out lib/features/ratings/models/rating.g.dart --part rating.dart \
//     --int-fields id,userId,professionalId \
//     --enum-fields type:RatingType
//
// Uso real contra un backend vivo — reemplazá --openapi-file por:
//   --openapi-url http://localhost:3000/tekoapp-backend/api/swagger-json
// (mismo patrón que TekoApp-Frontend-Web/scripts/generate-api-types.mjs; en CI apunta al
// swagger-json del ambiente desplegado, ver CODEGEN.md).

import 'dart:convert';
import 'dart:io';

class _Options {
  _Options({
    required this.schemaName,
    required this.className,
    required this.out,
    required this.partOf,
    this.openapiFile,
    this.openapiUrl,
    this.intFields = const {},
    this.enumFields = const {},
    this.refFields = const {},
    this.renameFields = const {},
  });

  final String schemaName;
  final String className;
  final String out;
  final String partOf;
  final String? openapiFile;
  final String? openapiUrl;
  final Set<String> intFields;
  final Map<String, String> enumFields;

  /// Campo del schema (clave del JSON) → clase Dart que ya tiene su propio
  /// `factory <Clase>.fromJson(Map<String, dynamic> json)` — para objetos anidados vía `$ref`
  /// (directo o envuelto en `allOf`, patrón que usa `@nestjs/swagger` para adjuntar `nullable`
  /// junto a un `$ref`). No resuelve el schema referenciado: delega en el `fromJson` que el
  /// dominio ya tiene escrito a mano.
  final Map<String, String> refFields;

  /// Clave del JSON → nombre del parámetro Dart, para los pocos campos donde el backend expone
  /// una clave distinta al nombre que el modelo Dart ya usa (p.ej. `Service.users` → `client`,
  /// ver M-04/CODEGEN.md). El acceso a `json['<clave>']` sigue usando la clave del JSON; solo
  /// cambia el nombre del parámetro nombrado que se emite.
  final Map<String, String> renameFields;
}

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);

  final String raw;
  if (options.openapiFile != null) {
    raw = await File(options.openapiFile!).readAsString();
  } else if (options.openapiUrl != null) {
    raw = await _fetch(options.openapiUrl!);
  } else {
    stderr.writeln('Falta --openapi-file o --openapi-url.');
    exit(1);
  }

  final document = jsonDecode(raw) as Map<String, dynamic>;
  final schemas = (document['components'] as Map<String, dynamic>)['schemas']
      as Map<String, dynamic>;
  final schema = schemas[options.schemaName] as Map<String, dynamic>?;
  if (schema == null) {
    stderr.writeln(
      'Schema "${options.schemaName}" no encontrado en components.schemas.',
    );
    exit(1);
  }

  final code = _generate(schema, options);

  final outFile = File(options.out);
  await outFile.create(recursive: true);
  await outFile.writeAsString(code);
  stdout.writeln('Generado ${options.out}');
}

String _generate(Map<String, dynamic> schema, _Options options) {
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
    final expression = _castExpressionFor(
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

String _castExpressionFor({
  required String name,
  required Map<String, dynamic> schema,
  required bool nullable,
  required _Options options,
}) {
  final type = schema['type'] as String?;
  final format = schema['format'] as String?;
  final enumTarget = options.enumFields[name];
  final refTarget = options.refFields[name];
  final suffix = nullable ? '?' : '';
  final access = "json['$name']";

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

  if (type == 'array') {
    final itemsType = (schema['items'] as Map<String, dynamic>?)?['type'];
    if (itemsType == 'string') {
      if (nullable) {
        return '($access as List<dynamic>?)?.cast<String>()';
      }
      return '($access as List<dynamic>).cast<String>()';
    }
    if (itemsType == 'number') {
      // Mismo criterio que el escalar: sin `format: int32` en el schema, `--int-fields` decide
      // si cada elemento es `int` o `double` (ver "Limitaciones conocidas" en CODEGEN.md).
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
      'arrays de string/number. Extendé _castExpressionFor en '
      'tool/openapi_codegen/generate_model.dart.',
    );
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
    // v1: objeto libre sin `additionalProperties` tipado — ver el comentario de cabecera.
    return '$access as Map<String, dynamic>$suffix';
  }

  throw UnsupportedError(
    'Tipo de schema no soportado para "$name": $schema. '
    'Extendé _castExpressionFor en tool/openapi_codegen/generate_model.dart.',
  );
}

Future<String> _fetch(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException(
        'GET $url devolvió ${response.statusCode}',
        uri: Uri.parse(url),
      );
    }
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

_Options _parseArgs(List<String> args) {
  String? schemaName;
  String? className;
  String? out;
  String? partOf;
  String? openapiFile;
  String? openapiUrl;
  var intFields = <String>{};
  var enumFields = <String, String>{};
  var refFields = <String, String>{};
  var renameFields = <String, String>{};

  for (var i = 0; i < args.length; i += 2) {
    final flag = args[i];
    final value = args[i + 1];
    switch (flag) {
      case '--schema':
        schemaName = value;
      case '--class':
        className = value;
      case '--out':
        out = value;
      case '--part':
        partOf = value;
      case '--openapi-file':
        openapiFile = value;
      case '--openapi-url':
        openapiUrl = value;
      case '--int-fields':
        intFields = value.split(',').toSet();
      case '--enum-fields':
        enumFields = {
          for (final pair in value.split(','))
            pair.split(':')[0]: pair.split(':')[1],
        };
      case '--ref-fields':
        refFields = {
          for (final pair in value.split(','))
            pair.split(':')[0]: pair.split(':')[1],
        };
      case '--rename-fields':
        renameFields = {
          for (final pair in value.split(','))
            pair.split(':')[0]: pair.split(':')[1],
        };
      default:
        stderr.writeln('Flag desconocido: $flag');
        exit(1);
    }
  }

  if (schemaName == null ||
      className == null ||
      out == null ||
      partOf == null) {
    stderr.writeln(
      'Uso: dart run tool/openapi_codegen/generate_model.dart --schema <Nombre> '
      '--class <Clase> --out <archivo.g.dart> --part <archivo.dart> '
      '(--openapi-file <path> | --openapi-url <url>) '
      '[--int-fields a,b] [--enum-fields campo:Enum,...] '
      '[--ref-fields campo:Clase,...] [--rename-fields claveJson:campoDart,...]',
    );
    exit(1);
  }

  return _Options(
    schemaName: schemaName,
    className: className,
    out: out,
    partOf: partOf,
    openapiFile: openapiFile,
    openapiUrl: openapiUrl,
    intFields: intFields,
    enumFields: enumFields,
    refFields: refFields,
    renameFields: renameFields,
  );
}
