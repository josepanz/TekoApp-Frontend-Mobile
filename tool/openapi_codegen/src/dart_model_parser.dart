// Extrae, de un archivo de modelo Dart — escrito a mano O generado, el verificador de drift trata
// ambos igual (ver openspec/changes/platform-hardening-2026-09/CODEGEN.md) — los campos
// declarados de UNA clase puntual: nombre, tipo Dart tal cual aparece en el código, y si es
// nullable (el tipo termina en `?`).
//
// Deliberadamente NO es un analizador de Dart completo (no usa el `analyzer` package: este repo
// prefiere script propio sin dependencias nuevas, mismo criterio que `model_generator.dart` — ver
// CODEGEN.md, "Por qué script propio"). Es un parser por línea + conteo de llaves que confía en
// que el repo corre `dart format` (una declaración por línea, un `;` de cierre) — ver
// "Limitaciones conocidas" en CODEGEN.md sobre qué formas de código puede no reconocer.

/// Un campo de instancia tal cual está declarado en el modelo Dart.
class DartModelField {
  const DartModelField({
    required this.name,
    required this.declaredType,
    required this.nullable,
  });

  /// Nombre del campo/parámetro.
  final String name;

  /// Tipo tal cual aparece en el código, SIN el sufijo `?` (ej. `List<BudgetLineItem>`, `int`,
  /// `Map<String, dynamic>`).
  final String declaredType;

  final bool nullable;

  @override
  String toString() => '$declaredType${nullable ? '?' : ''} $name';

  @override
  bool operator ==(Object other) =>
      other is DartModelField &&
      other.name == name &&
      other.declaredType == declaredType &&
      other.nullable == nullable;

  @override
  int get hashCode => Object.hash(name, declaredType, nullable);
}

/// Encabezado de una declaración de clase a nivel de archivo (columna 0), capturando el nombre.
/// Acepta modificadores (`sealed`/`abstract`/`base`/`final`/`interface`) y anotaciones simples
/// antes de `class`.
final RegExp _classOrEnumHeader = RegExp(
  r'^(?:@[\w.]+(?:\([^)]*\))?\s*)*'
  r'(?:sealed\s+|abstract\s+|base\s+|final\s+|interface\s+)*'
  r'(class|enum|mixin)\s+(\w+)',
  multiLine: true,
);

/// Declaración de campo de instancia: `[final] Tipo[<Generico>][?] nombre;` — un campo por línea
/// (formato estándar de `dart format`). El prefijo `final`/`const`/`static const` es opcional para
/// cubrir también clases con campos mutables (ej. un "draft" de estado local de UI).
final RegExp _fieldDeclaration = RegExp(
  r'^\s*(?:final\s+|static\s+const\s+|const\s+)?'
  r'([A-Za-z_]\w*(?:<[^;=]+>)?\??)\s+'
  r'([a-zA-Z_]\w*)\s*;\s*$',
);

/// Nombres de todas las clases/enums/mixins declarados a nivel de archivo — usado por el chequeo
/// de cobertura (`drift_checker.dart`): cada uno debe estar mapeado a un schema o exento con
/// motivo en `model_mapping.dart`.
List<String> topLevelTypeNamesIn(String source) {
  return [
    for (final match in _classOrEnumHeader.allMatches(source)) match.group(2)!,
  ];
}

/// Extrae los campos de instancia de la clase `className` en `source`. Tira `StateError` si no
/// encuentra una clase con ese nombre.
///
/// No distingue campos requeridos de opcionales por sí mismo — eso lo decide enteramente la
/// nulabilidad del TIPO declarado (`Tipo?` vs `Tipo`), que es lo que le importa a un consumidor:
/// un campo `required` en el constructor pero de tipo nullable puede seguir recibiendo `null`
/// del backend.
List<DartModelField> parseDartFields(String source, String className) {
  final headerPattern = RegExp(
    '^(?:@[\\w.]+(?:\\([^)]*\\))?\\s*)*'
    '(?:sealed\\s+|abstract\\s+|base\\s+|final\\s+|interface\\s+)*'
    'class\\s+${RegExp.escape(className)}\\b[^{]*\\{',
    multiLine: true,
  );
  final match = headerPattern.firstMatch(source);
  if (match == null) {
    throw StateError(
      'No se encontró "class $className { ... }" en el archivo — ¿el nombre en '
      'model_mapping.dart coincide con el de la clase Dart?',
    );
  }

  final fields = <DartModelField>[];
  final lines = source.substring(match.end).split('\n');
  var depth = 1; // ya consumimos la '{' que abre la clase.

  for (final line in lines) {
    if (depth <= 0) break;

    if (depth == 1) {
      final fieldMatch = _fieldDeclaration.firstMatch(line);
      if (fieldMatch != null) {
        final rawType = fieldMatch.group(1)!;
        final name = fieldMatch.group(2)!;
        final nullable = rawType.endsWith('?');
        fields.add(
          DartModelField(
            name: name,
            declaredType:
                nullable ? rawType.substring(0, rawType.length - 1) : rawType,
            nullable: nullable,
          ),
        );
      }
    }

    for (final code in line.codeUnits) {
      if (code == 0x7B) {
        depth++;
      } else if (code == 0x7D) {
        depth--;
        if (depth <= 0) break;
      }
    }
  }

  return fields;
}
