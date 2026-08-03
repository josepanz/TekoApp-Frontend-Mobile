# Reglas de testing (Flutter)

> Adaptación del estándar ya usado en `TekoApp-Backend`/`TekoApp-Web` — mismo espíritu (AAA,
> nombres en español describiendo comportamiento, mockear el límite de red), sintaxis Flutter.

- SIEMPRE generar el test correspondiente (`*_test.dart`) al crear o modificar un provider, widget
  de pantalla, o función de `core/`.
- NUNCA pegarle al backend real en tests — mockear `dio` (con `dio_test`/interceptor fake, a
  confirmar en `decisions.md` qué paquete se usa) o el provider de datos subyacente, nunca ambos a
  la vez de forma redundante.
- Nombres de test en español, describiendo el COMPORTAMIENTO esperado, no el método:
  - ❌ `test('llama a fetchUsers')`
  - ✅ `test('muestra un estado vacío cuando no hay servicios todavía')`
- Patrón AAA (Arrange / Act / Assert) obligatorio — nunca mezclar las tres fases en una línea.
- Widget tests: usar `WidgetTester` de `flutter_test`, verificar comportamiento visible (texto,
  estados de carga/error/vacío, navegación), nunca estado interno de un widget privado.
- Providers de Riverpod: testear con un `ProviderContainer` de test aislado por test (no
  compartido entre tests) — equivalente a `createTestQueryClient()` de `TekoApp-Web`.
- 0 warnings/errores en el analizador (`flutter analyze`) y en la corrida de tests — mismo
  estándar que los otros 2 repos.

## Pendiente de decidir (no asumir, confirmar en Fase 0001/0002)

- Framework de testing más allá de `flutter_test` (¿`mocktail`? ¿`mockito`?) — ver
  `openspec/decisions.md`, listado explícitamente como "no decidido".
- Si hay e2e (`integration_test`) y qué flujos cubre — probablemente login + un flujo CRUD
  representativo, mismo alcance que Playwright en `TekoApp-Web`, no buscar 100% de cobertura e2e.

## Comandos (una vez exista `pubspec.yaml`)

- `flutter test` — todos los tests
- `flutter test --coverage` — con cobertura
- `flutter analyze` — analizador estático (equivalente a lint)
