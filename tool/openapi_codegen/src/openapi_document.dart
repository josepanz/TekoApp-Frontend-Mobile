// I/O compartido para leer un documento OpenAPI completo, sea de un archivo local (snapshot) o de
// un backend real corriendo — usado por `generate_model.dart` y por `check_drift.dart` (ver
// openspec/changes/platform-hardening-2026-09/CODEGEN.md). Antes vivía duplicado dentro de
// `generate_model.dart`; se extrajo acá cuando `check_drift.dart` necesitó exactamente la misma
// lectura.

import 'dart:convert';
import 'dart:io';

/// Lee el documento OpenAPI completo desde `openapiFile` (snapshot local) o `openapiUrl` (backend
/// real, mismo patrón que `TekoApp-Frontend-Web/scripts/generate-api-types.mjs`). Exactamente uno
/// de los dos debe venir no-nulo.
Future<Map<String, dynamic>> loadOpenApiDocument({
  String? openapiFile,
  String? openapiUrl,
}) async {
  final String raw;
  if (openapiFile != null) {
    raw = await File(openapiFile).readAsString();
  } else if (openapiUrl != null) {
    raw = await _fetch(openapiUrl);
  } else {
    throw ArgumentError('Falta --openapi-file o --openapi-url.');
  }
  return jsonDecode(raw) as Map<String, dynamic>;
}

/// `document['components']['schemas']` ya casteado — el mapa `NombreDelSchema -> schema` que usan
/// tanto el generador como el verificador de drift.
Map<String, dynamic> schemasOf(Map<String, dynamic> document) {
  final components = document['components'] as Map<String, dynamic>?;
  final schemas = components?['schemas'] as Map<String, dynamic>?;
  if (schemas == null) {
    throw StateError(
      'El documento OpenAPI no tiene components.schemas — ¿es realmente un swagger-json?',
    );
  }
  return schemas;
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
