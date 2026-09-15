// Extrae, del `fromJson` de UN enum Dart, el conjunto de literales de string que reconoce — ver
// "Comparación de valores de enum" en
// openspec/changes/platform-hardening-2026-09/CODEGEN.md (§11.1) para el diseño completo y por
// qué hace falta esto además de `dart_model_parser.dart` (que solo ve la FORMA de un campo,
// "es un string", nunca los valores concretos que un enum Dart reconoce).
//
// Mismo criterio que el resto de `tool/openapi_codegen/`: script propio sin el paquete
// `analyzer`, parser deliberadamente pragmático (no un analizador de Dart completo) — ver
// docstring de `parseEnumFromJson` para el motivo exacto de CÓMO es pragmático acá.

/// Lo que el `fromJson` de un enum Dart reconoce, extraído de su código fuente.
class DartEnumFromJson {
  const DartEnumFromJson({
    required this.recognizedValues,
    required this.throwsOnUnknown,
  });

  /// Los literales de string (ej. `ACTIVE`, sin comillas) que el cuerpo del `fromJson` reconoce
  /// explícitamente — sea como patrón de un switch EXPRESSION (`'ACTIVE' => Enum.active`) o como
  /// `case 'ACTIVE':` de un switch STATEMENT clásico. Ver docstring de [parseEnumFromJson] para
  /// por qué la extracción no distingue cuál de las dos formas es.
  final Set<String> recognizedValues;

  /// `true` si el catch-all del switch (`_ => throw ...` / `default: throw ...`) relanza ante un
  /// valor no reconocido — un valor del schema que el Dart no cubre CRASHEA en runtime la próxima
  /// vez que llegue (severidad crítica, mismo criterio que `[NULABILIDAD]` cuando el schema es
  /// nullable y el modelo no). `false` si el catch-all devuelve un miembro real en silencio (ej.
  /// `AiDisclosureSource.fromJson`, que ante cualquier valor desconocido devuelve
  /// `userDeclaredAi`) — ahí un valor no cubierto no crashea, solo se mezcla con otro miembro sin
  /// que nada lo note (severidad advertencia, no crítica).
  final bool throwsOnUnknown;
}

/// Literal de string reconocible como valor de enum del backend: MAYÚSCULA_CON_GUIONES_BAJOS,
/// nunca texto libre (los mensajes de `ArgumentError` de este repo son siempre minúscula/mixta,
/// ej. `'ContractStatus desconocido: $value'` — esa cadena NO matchea este patrón porque no es
/// enteramente mayúscula, así que no se confunde con un valor de enum real).
final RegExp _upperSnakeLiteral = RegExp(r"'([A-Z][A-Z0-9_]*)'");

/// Busca el `fromJson` de `enumName` en `source` (el archivo `.dart` completo) y extrae los
/// literales que reconoce.
///
/// Cubre las dos formas reales que usa este repo (ver CODEGEN.md §11.1 para el catálogo completo
/// encontrado en el repo al construir esto):
/// - `factory Enum.fromJson(String value) { return switch (value) { 'X' => Enum.x, ... }; }`
///   (switch EXPRESSION dentro de un factory).
/// - `static Enum fromJson(String value) { switch (value) { case 'X': return Enum.x; ... } }`
///   (switch STATEMENT clásico dentro de un método static).
///
/// Deliberadamente NO distingue cuál de las dos formas es, ni intenta parsear la sintaxis exacta
/// del switch (arrow vs case/return): una vez que ubica el CUERPO del método (con conteo de
/// llaves, tolerante a que `dart format` parta un caso largo en 2 líneas — ver el caso real
/// `ContractStatus.pendingProfessionalSignature`, que envuelve así), extrae TODOS los literales
/// `'MAYÚSCULA_CON_GUIONES'` que aparecen adentro. Es una heurística a propósito laxa: distinguir
/// la sintaxis exacta de cada forma (arrow vs case) para extraer "solo los literales que son
/// realmente un caso, no cualquier string suelto" añade complejidad de parsing significativa para
/// un beneficio marginal — en la práctica, un literal enteramente en mayúsculas dentro del cuerpo
/// de un `fromJson(String value)` de un enum siempre es un valor reconocido, nunca coincide por
/// casualidad con un mensaje de error (que este repo siempre escribe en minúscula/mixta, ver
/// `_upperSnakeLiteral`).
///
/// Devuelve `null` si no encuentra un `fromJson` con ninguna de las dos formas de cabecera de
/// arriba — el caller debe tratar esto como "no se puede comparar este campo todavía" y reportarlo
/// explícitamente (`[ENUM SIN PARSEAR]` en `drift_checker.dart`), nunca asumir en silencio que no
/// hay drift.
DartEnumFromJson? parseEnumFromJson(String source, String enumName) {
  final escaped = RegExp.escape(enumName);
  final headerPatterns = [
    // factory Enum.fromJson(String value) {
    RegExp(
      'factory\\s+$escaped\\.fromJson\\s*\\(\\s*String\\s+\\w+\\s*\\)\\s*\\{',
    ),
    // static [const] Enum fromJson(String value) {
    RegExp(
      'static\\s+(?:const\\s+)?$escaped\\s+fromJson\\s*\\(\\s*String\\s+\\w+\\s*\\)\\s*\\{',
    ),
  ];

  for (final pattern in headerPatterns) {
    final match = pattern.firstMatch(source);
    if (match == null) continue;

    final body = _extractBraceBody(source, match.end);
    if (body == null) return null;

    final recognized = <String>{
      for (final m in _upperSnakeLiteral.allMatches(body)) m.group(1)!,
    };
    return DartEnumFromJson(
      recognizedValues: recognized,
      throwsOnUnknown: body.contains('throw'),
    );
  }
  return null;
}

/// Devuelve el contenido entre `source[afterOpenBrace]` y la `}` que cierra la `{` YA consumida
/// (por eso `depth` arranca en 1) — conteo de llaves carácter a carácter (no línea a línea, a
/// diferencia de `dart_model_parser.dart`) para no depender de que un caso largo quepa en una sola
/// línea. `null` si el archivo está truncado/mal formado y nunca cierra.
String? _extractBraceBody(String source, int afterOpenBrace) {
  var depth = 1;
  for (var i = afterOpenBrace; i < source.length; i++) {
    final unit = source.codeUnitAt(i);
    if (unit == 0x7B) {
      depth++;
    } else if (unit == 0x7D) {
      depth--;
      if (depth == 0) return source.substring(afterOpenBrace, i);
    }
  }
  return null;
}
