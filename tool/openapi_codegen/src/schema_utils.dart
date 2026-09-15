// Utilidades de bajo nivel para leer un schema de OpenAPI (`components.schemas.<Nombre>`),
// compartidas entre el generador (`model_generator.dart`) y el verificador de drift
// (`drift_checker.dart`) — ver openspec/changes/platform-hardening-2026-09/CODEGEN.md. Viven acá
// para que ninguno de los dos duplique la misma lógica de resolución de `$ref`/`allOf`/arrays.

/// Nombre del schema referenciado por `schema`, si lo referencia directo (`$ref`) o envuelto en
/// `allOf: [{$ref}]` (patrón que usa `@nestjs/swagger` para adjuntar `nullable` junto a un
/// `$ref`) — o `null` si `schema` no referencia ningún otro schema.
String? refNameOf(Map<String, dynamic> schema) {
  final direct = schema[r'$ref'] as String?;
  if (direct != null) return direct.split('/').last;

  final allOf = schema['allOf'] as List?;
  if (allOf != null && allOf.isNotEmpty) {
    final first = allOf.first as Map<String, dynamic>;
    final ref = first[r'$ref'] as String?;
    if (ref != null) return ref.split('/').last;
  }
  return null;
}

/// El schema de `items` si `schema` es `type: array`, o `null` si no lo es.
Map<String, dynamic>? arrayItemsOf(Map<String, dynamic> schema) {
  if (schema['type'] != 'array') return null;
  return schema['items'] as Map<String, dynamic>?;
}
