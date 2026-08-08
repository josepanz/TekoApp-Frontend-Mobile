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

## Mocks: `mocktail`

Decidido en la Fase 0001 (ver `openspec/decisions.md`) — sin code generation, a diferencia de
`mockito`. Ver `test/core/api_client/envelope_interceptor_test.dart` como ejemplo del patrón
(`class _MockHandler extends Mock implements X {}`).

## E2E: decidido — flujo completo como test de widgets, no `integration_test/` todavía

**Decisión (2026-08-07)**: el flujo e2e (login → home → Mi perfil → logout, mismo alcance que
Playwright en `TekoApp-Web` — no se busca 100% de cobertura e2e) vive en
`test/e2e/login_profile_logout_test.dart` como un test de widgets normal (`flutter test`), no en
`integration_test/`. Motivo: este entorno de desarrollo no tenía un emulador/dispositivo
disponible para correr `integration_test` de verdad (`flutter test integration_test/` necesita un
device real, a diferencia de un test de widgets normal). El test en sí SÍ es end-to-end real —
arranca la app completa sin fijar `sessionProvider` a mano, solo mockea el límite de red (`Dio`) y
el `MethodChannel` de `flutter_secure_storage` — solo corre en el binding de test en vez de en un
device.

`integration_test/` (paquete ya declarado en `pubspec.yaml`) sigue vacío — correr la suite ahí
requiere un emulador Android o simulador iOS real, tarea de quien tenga uno disponible, no un
cambio de código.

## Comandos (una vez exista `pubspec.yaml`)

- `flutter test` — todos los tests
- `flutter test --coverage` — con cobertura
- `flutter analyze` — analizador estático (equivalente a lint)
