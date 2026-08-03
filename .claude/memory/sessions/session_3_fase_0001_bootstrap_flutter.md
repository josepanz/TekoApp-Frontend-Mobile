# Sesión 3 — 2026-08-03 — Fase 0001: bootstrap del código Flutter

## Actualización (mismo día, tras correr el CI real por primera vez)

- El CI real (con el SDK de Flutter instalado, a diferencia de donde se escribió el código)
  encontró 3 archivos mal formateados (`dart format`) — corregidos a mano: líneas de código
  (no comentarios) de más de 80 columnas en `api_client.dart`, `login_screen.dart` y
  `envelope_interceptor_test.dart`. `flutter analyze` ya pasaba antes de este fix.
- `brand/` ahora vive de verdad DENTRO de este repo (copia local de `banner.png`/`logo.png`/
  `manual-de-marca.png`, ya no una referencia relativa a `TekoApp-Backend/brand/`) — mismo
  criterio que backend/web, cada repo con su propia copia.
- Sacada la sección "Cómo arrancar la próxima sesión (con un agente de IA)" del `README.md` — un
  README describe el proyecto a cualquier lector, no el protocolo de una IA específica (eso ya
  vive en `.claude/memory/memory.md`, que no cambió).
- Nuevo `CONTRIBUTING.md` (raíz del repo, no `.claude/`) — guía paso a paso para alguien sin
  experiencia en Flutter: conceptos base (Widget, Riverpod, go_router), ejemplos de ajuste menor/
  mayor/feature nueva, i18n, testing.
- `.github/workflows/build.yml` ahora es consciente de los 3 ambientes (`dev`/`qa`/`prod`, mismo
  mapeo de ramas que backend/web) vía un input de `workflow_dispatch` — pasa el `API_BASE_URL`
  correspondiente por `--dart-define`. Documentado en `openspec/decisions.md` qué falta
  exactamente para releases reales a las stores (cuentas, Firebase, backend desplegado) — nada de
  eso es una decisión técnica pendiente, son cuentas/infra externas que no existen todavía.
- **Bug real reportado por el usuario probando en el browser**: `service.professional.user`
  crasheaba en el detail view de servicios (`TekoApp-Frontend-Web`). Causa raíz en
  `TekoApp-Backend`: `findServiceByReferenceId` incluía `professional: true` sin anidar
  `include: { user: true }`, a pesar de que `ServiceDetailResponseDTO` documenta
  `professional.user`. Corregido el include (mismo patrón que ya usaban otros métodos del mismo
  archivo) + agregado `service.professional?.user` en el frontend como defensa adicional.

## Qué se hizo

- Creado `pubspec.yaml` con el stack ya decidido: `flutter_riverpod`, `go_router`, `dio`,
  `flutter_localizations`+`intl`. Testing: `mocktail` (nueva decisión, ver `openspec/decisions.md`
  — sin code generation, a diferencia de `mockito`).
- Creada la estructura de `lib/` completa según `.claude/rules/flutter-architecture.md`:
  - `core/api_client/` — `ApiClient` (wrapper de `Dio`) + `EnvelopeInterceptor` (desenvuelve
    `{success,data,...}`, mismo contrato que `apiFetch` de TekoApp-Web) + su provider.
  - `core/auth/` — `SessionState`/`sessionProvider` **placeholder** (siempre "sin sesión") — el
    login real (nonce + RSA-OAEP) es Fase 0002, sin adelantarse a la decisión pendiente de
    almacenamiento seguro de tokens.
  - `core/config/env.dart` — `API_BASE_URL` vía `--dart-define`, default apuntando al backend
    local (`10.0.2.2` para emulador Android).
  - `core/theme/app_theme.dart` — `ThemeData` claro/oscuro con los colores de marca reales
    (`#28A745`/`#17BEBB`/`#0D1B2A`/`#F5F7FA`) copiados tal cual de `tokens.json`, marcado
    explícitamente como placeholder hasta que exista el generador Dart real (Fase 0002).
  - `features/auth/` y `features/home/` con el patrón `data/providers/models/widgets` — pantallas
    placeholder (`LoginScreen`, `HomeScreen`) para tener un destino real en `go_router`.
  - `shared/widgets/async_state_view.dart` — wrapper genérico de loading/error/empty.
  - `l10n/{es,en}.arb` + `l10n.yaml` — catálogo mínimo (`appTitle`, saludo, textos de login).
- `lib/main.dart` + `lib/app.dart` — `ProviderScope` + `MaterialApp.router`, sin guards de sesión
  todavía (el router no gatea ninguna ruta hasta que `sessionProvider` sea real).
- Tests: `test/app_test.dart` (smoke test — la app arranca sin excepciones) y
  `test/core/api_client/envelope_interceptor_test.dart` (mockea `ResponseInterceptorHandler` con
  `mocktail`, verifica el unwrap del envelope).
- CI/CD (nueva decisión, ver `openspec/decisions.md`): `.github/workflows/ci.yml` (analyze+test en
  cada push/PR) y `.github/workflows/build.yml` (disparo manual, build de validación — APK debug
  Android + iOS `--no-codesign` para simulador, **sin publicar a ninguna store todavía**, no hay
  cuentas de Play Console/Apple Developer).
- `README.md`: sección nueva "Cómo correr esta app localmente" — prerequisitos, cómo correr en
  Android por USB/emulador y en iOS (solo desde Mac) por simulador/dispositivo físico.
- Actualizados `.claude/CLAUDE.md`, `.claude/rules/flutter-architecture.md`,
  `.claude/rules/test.md` y `openspec/decisions.md` para reflejar que la Fase 0001 ya no es
  "el plan" sino el estado real — quitadas las notas de "no hay código todavía".

## Cambio organizacional pedido a mitad de sesión (aplica a los 3 repos, no solo mobile)

El usuario pidió sacar los assets de marca (`brand/`: logo, banner, manual de marca) de
`.claude/documentation/` en `TekoApp-Backend` y `TekoApp-Web` — son inherentes al proyecto, no a
la IA que asiste — y moverlos a una carpeta `brand/` en la raíz de cada repo. Se hizo `git mv` en
ambos (frontend-web tenía una copia duplicada de estos 3 archivos; ya existía `public/brand/` con
`banner.png`/`logo.png` para el uso real de la app, así que solo `manual-de-marca.png` era
realmente nuevo ahí) y se actualizaron las referencias en `README.md` de los 3 repos +
`how-to-contribute.md`/`design-system.md` en frontend-web. Mobile no tenía copia propia, solo
referencias relativas al backend — se actualizaron a la nueva ruta `../TekoApp-Backend/brand/`.

## Errores encontrados y su solución

- Ninguno de código (no se pudo correr `flutter analyze`/`flutter test` — el SDK de Flutter no
  está instalado en el entorno donde se escribió este código; **queda pendiente correrlos en la
  primera sesión con el SDK real instalado**, ver "Pendiente para la próxima sesión").

## Estado al cierre

- `flutter analyze`/`flutter test`/`flutter pub get`: **sin correr, no verificado** — el código se
  escribió a mano siguiendo la sintaxis de Dart/Flutter/Riverpod/go_router/dio conocida, pero no
  hay confirmación de que compile limpio hasta que alguien con el SDK instalado lo corra.
- Backend/Frontend-Web: sin cambios relacionados a esta fase (solo el movimiento de `brand/`).

## Pendiente para la próxima sesión

1. **Primero que nada**: con el SDK de Flutter instalado, correr `flutter pub get`,
   `flutter gen-l10n`, `flutter analyze --fatal-infos`, `flutter test` — corregir cualquier error
   de sintaxis/import antes de escribir código nuevo encima de este esqueleto.
2. Arrancar `openspec/changes/0002-auth-and-design-system.md`: confirmar el paquete de
   almacenamiento seguro de tokens, implementar el login real (nonce + RSA-OAEP —
   **verificar el padding contra el backend real antes de dar por resuelto**), y el generador
   real de `tokens.json` → Dart (reemplaza el placeholder de `app_theme.dart`).
3. Una vez que `flutter analyze` corra limpio, correr `/graphify .` para generar el grafo de
   conocimiento (no existía código para graficar antes de esta sesión).
