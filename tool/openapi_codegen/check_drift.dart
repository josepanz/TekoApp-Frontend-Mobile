// Verifica que los modelos Dart declarados en `model_mapping.dart` sigan coincidiendo con el
// swagger real del backend — sin importar si cada modelo se escribió a mano o se generó con
// `generate_model.dart` (ver openspec/changes/platform-hardening-2026-09/CODEGEN.md, "Cómo
// interpretar un reporte de drift").
//
// Uso:
//   dart run tool/openapi_codegen/check_drift.dart --openapi-url http://localhost:3000/tekoapp-backend/api/swagger-json
//   dart run tool/openapi_codegen/check_drift.dart --openapi-file tool/openapi_codegen/fixtures/swagger.local-example.json
//
// Correr desde la raíz del repo (las rutas de `model_mapping.dart` son relativas a ahí). Sale con
// código 1 si encuentra drift de severidad "crítica" (campo faltante, tipo/nulabilidad
// incompatible, schema/modelo no encontrado, clase sin registrar) — pensado para CI (ver
// CODEGEN.md, "Sobre CI", para las condiciones bajo las que conviene wireearlo).

import 'dart:io';

import 'model_mapping.dart';
import 'src/drift_checker.dart';
import 'src/openapi_document.dart';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  if (parsed.openapiFile == null && parsed.openapiUrl == null) {
    stderr.writeln(
      'Uso: dart run tool/openapi_codegen/check_drift.dart '
      '(--openapi-file <path> | --openapi-url <url>)',
    );
    exit(1);
  }

  final Map<String, dynamic> document;
  try {
    document = await loadOpenApiDocument(
      openapiFile: parsed.openapiFile,
      openapiUrl: parsed.openapiUrl,
    );
  } catch (e) {
    stderr.writeln('No se pudo cargar el documento OpenAPI: $e');
    exit(1);
  }
  final schemas = schemasOf(document);

  final findings = <DriftFinding>[];
  final modelFileSources = <String, String>{};
  final enumFileSources = <String, String>{};

  for (final mapping in modelMappings) {
    final source = _readModelFile(mapping.dartFile, findings);
    if (source == null) continue;
    modelFileSources[mapping.dartFile] = source;
    findings.addAll(
      checkMapping(mapping: mapping, schemas: schemas, dartSource: source),
    );

    if (mapping.enumFields.isEmpty) continue;
    final schema = schemas[mapping.schemaName] as Map<String, dynamic>?;
    if (schema == null) {
      continue; // ya se reportó [SCHEMA NO ENCONTRADO] arriba.
    }
    for (final enumMapping in mapping.enumFields.values) {
      enumFileSources.putIfAbsent(enumMapping.dartFile, () {
        final file = File(enumMapping.dartFile);
        return file.existsSync() ? file.readAsStringSync() : '';
      });
    }
    findings.addAll(
      checkEnumFields(
        mapping: mapping,
        schema: schema,
        enumFileSources: enumFileSources,
      ),
    );
  }

  for (final exemption in localModelExemptions) {
    modelFileSources.putIfAbsent(exemption.dartFile, () {
      final file = File(exemption.dartFile);
      return file.existsSync() ? file.readAsStringSync() : '';
    });
  }

  for (final file in _discoverModelFiles()) {
    modelFileSources.putIfAbsent(file, () => File(file).readAsStringSync());
  }

  findings.addAll(
    checkCoverage(
      mappings: modelMappings,
      exemptions: localModelExemptions,
      modelFileSources: modelFileSources,
    ),
  );

  _printReport(findings);

  final hasCritical = findings.any((f) => f.severity == Severity.critical);
  exit(hasCritical ? 1 : 0);
}

String? _readModelFile(String dartFile, List<DriftFinding> findings) {
  final file = File(dartFile);
  if (!file.existsSync()) {
    findings.add(
      DriftFinding(
        className: '-',
        schemaName: '-',
        field: '-',
        kind: DriftKind.modelNotFound,
        severity: Severity.critical,
        expected: 'no existe el archivo "$dartFile" (¿se movió o se borró?)',
      ),
    );
    return null;
  }
  return file.readAsStringSync();
}

/// Todos los `.dart` bajo `lib/features/*/models/` que no sean `.g.dart` (generados) — usado por
/// el chequeo de cobertura para detectar un modelo NUEVO que nadie registró todavía en
/// `model_mapping.dart`. Devuelve rutas relativas con `/` (no `\`), consistente con las rutas que
/// usa `model_mapping.dart`.
List<String> _discoverModelFiles() {
  final modelsDir = Directory('lib/features');
  if (!modelsDir.existsSync()) return const [];

  final result = <String>[];
  for (final entity in modelsDir.listSync(recursive: true)) {
    if (entity is! File) continue;
    final normalized = entity.path.replaceAll(r'\', '/');
    if (!normalized.contains('/models/')) continue;
    if (!normalized.endsWith('.dart')) continue;
    if (normalized.endsWith('.g.dart')) continue;
    result.add(normalized);
  }
  result.sort();
  return result;
}

void _printReport(List<DriftFinding> findings) {
  if (findings.isEmpty) {
    stdout.writeln(
      'check_drift: sin drift — todos los modelos mapeados coinciden con el swagger.',
    );
    return;
  }

  final critical =
      findings.where((f) => f.severity == Severity.critical).toList();
  final warn = findings.where((f) => f.severity == Severity.warn).toList();

  stdout.writeln('check_drift: ${findings.length} hallazgo(s) '
      '(${critical.length} crítico(s), ${warn.length} advertencia(s)).\n');

  if (critical.isNotEmpty) {
    stdout.writeln('=== CRÍTICOS (${critical.length}) ===');
    for (final f in critical) {
      stdout.writeln('- ${f.describe()}');
    }
    stdout.writeln();
  }

  if (warn.isNotEmpty) {
    stdout.writeln('=== ADVERTENCIAS (${warn.length}) ===');
    for (final f in warn) {
      stdout.writeln('- ${f.describe()}');
    }
    stdout.writeln();
  }
}

class _ParsedArgs {
  _ParsedArgs({this.openapiFile, this.openapiUrl});

  final String? openapiFile;
  final String? openapiUrl;
}

_ParsedArgs _parseArgs(List<String> args) {
  String? openapiFile;
  String? openapiUrl;
  for (var i = 0; i < args.length; i += 2) {
    final flag = args[i];
    final value = i + 1 < args.length ? args[i + 1] : null;
    switch (flag) {
      case '--openapi-file':
        openapiFile = value;
      case '--openapi-url':
        openapiUrl = value;
      default:
        stderr.writeln('Flag desconocido: $flag');
        exit(1);
    }
  }
  return _ParsedArgs(openapiFile: openapiFile, openapiUrl: openapiUrl);
}
