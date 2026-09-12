// Genera un `<modelo>.g.dart` (`part of`, con el `fromJson`) desde un schema real de
// OpenAPI/swagger — ver openspec/changes/platform-hardening-2026-09/CODEGEN.md para el diseño
// completo y el criterio de cada dominio migrado.
//
// La lógica de generación (qué expresión Dart le corresponde a cada shape de OpenAPI) vive en
// `tool/openapi_codegen/src/model_generator.dart`, separada de este script para que
// `test/tool/openapi_codegen/model_generator_test.dart` la pueda importar y testear directo, sin
// pasar por `Process.run` ni por I/O de archivo/red. Este archivo es solo el CLI: parsea
// argumentos, lee el documento OpenAPI (archivo o URL real) y escribe el resultado.
//
// v1: cubre los shapes que aparecen en `RatingDetailResponseDTO` (string, number, boolean,
// enums de string, date-time, objetos libres). No resuelve `$ref` a otros schemas ni arrays de
// objetos.
//
// v2 (M-04, dominios payments/services/professionals): agrega `--ref-fields` (objeto anidado vía
// `$ref` directo o `allOf: [{$ref}]`, delega en el `fromJson` que la clase Dart ya tiene escrito
// a mano), `--rename-fields` (clave del JSON con un nombre de parámetro Dart distinto, ver
// `Service.users` → `client`) y arrays de `string` (`type: array, items: {type: string}` →
// `List<String>`).
//
// v3 (M-04, dominio promotions): agrega arrays de `number` (`type: array, items: {type:
// number}` → `List<int>` si el campo está en `--int-fields`, `List<double>` si no — mismo
// criterio que ya existía para escalares, ver "Limitaciones conocidas" en CODEGEN.md sobre
// `int` vs `double`).
//
// v4 (M-04, dominio contracts): agrega arrays de OBJETOS anidados (`type: array, items: {$ref:
// ...}` → `List<Clase>`) — reutiliza el mismo `--ref-fields campo:Clase` que ya resolvía un
// objeto anidado singular; ahora también resuelve el elemento de un array. Cierra la limitación
// documentada desde la v1 ("no resuelve arrays de objetos anidados") que hasta esta ronda
// bloqueaba migrar `contracts` (`ContractContentSnapshot.lineItems: ContractLineItemSnapshot[]`).
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

import 'dart:io';

import 'src/model_generator.dart';
import 'src/openapi_document.dart';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);

  if (parsed.openapiFile == null && parsed.openapiUrl == null) {
    stderr.writeln('Falta --openapi-file o --openapi-url.');
    exit(1);
  }

  final document = await loadOpenApiDocument(
    openapiFile: parsed.openapiFile,
    openapiUrl: parsed.openapiUrl,
  );
  final schemas = schemasOf(document);
  final schema = schemas[parsed.options.schemaName] as Map<String, dynamic>?;
  if (schema == null) {
    stderr.writeln(
      'Schema "${parsed.options.schemaName}" no encontrado en components.schemas.',
    );
    exit(1);
  }

  final code = generateModelSource(schema, parsed.options);

  final outFile = File(parsed.options.out);
  await outFile.create(recursive: true);
  await outFile.writeAsString(code);
  stdout.writeln('Generado ${parsed.options.out}');
}

class _ParsedArgs {
  _ParsedArgs({required this.options, this.openapiFile, this.openapiUrl});

  final ModelGenOptions options;
  final String? openapiFile;
  final String? openapiUrl;
}

_ParsedArgs _parseArgs(List<String> args) {
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

  return _ParsedArgs(
    options: ModelGenOptions(
      schemaName: schemaName,
      className: className,
      out: out,
      partOf: partOf,
      intFields: intFields,
      enumFields: enumFields,
      refFields: refFields,
      renameFields: renameFields,
    ),
    openapiFile: openapiFile,
    openapiUrl: openapiUrl,
  );
}
