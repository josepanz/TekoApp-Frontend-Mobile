# WORKPLAN — Endurecimiento de plataforma, tajada Mobile (`platform-hardening-2026-09`)

> **Auditoría y especificación**: Opus 5 (2026-09-04), sobre la rama `audit/2026-09-04`,
> partiendo de `develop` en `4be1343`.
> **Ejecución**: Sonnet, workflow por workflow, en el orden de este archivo.
>
> Este archivo es autocontenido: no hace falta leer la conversación que lo originó ni la
> auditoría transversal. Todo lo que el modelo ejecutor necesita (contexto, causa raíz,
> cambio, tests, criterios de aceptación, comando de verificación y mensaje de commit)
> está acá.
>
> Auditoría transversal completa (contexto, no requerido para ejecutar):
> `TekoApp-Backend/openspec/specs/platform-audit-2026-09.md`.

---

## 0. Cómo usar este archivo

- **Un workflow = una sesión de trabajo.** No mezclar workflows en un mismo commit.
- Cada tarea tiene un ID (`B-01`, `M-02`, …). Al terminarla, marcá su casilla en la tabla del
  §6 y escribí en la misma línea el hash del commit.
- **Antes de cambiar código, ejecutá la "Verificación previa" de la tarea.** Los números de
  línea de este documento son del commit de la rama `audit/2026-09-04` al 2026-09-04 y pueden
  correrse. Si la verificación previa NO reproduce el problema descrito, **no toques nada**:
  anotalo en la tabla del §6 como "no reproduce" con lo que encontraste, y seguí con la
  siguiente.
- Los hallazgos marcados **[VERIFICADO A MANO]** los confirmé abriendo el archivo yo mismo.
  Los demás vienen de auditoría delegada y por eso traen verificación previa obligatoria.
  (De la pasada delegada, **4 hallazgos vinieron con datos mal** — entre ellos la ruta del
  interceptor de refresh, que el agente ubicó en `core/api_client/` cuando vive en
  `core/auth/`. Por eso la verificación previa no es ceremonia.)

---

## 0.1 Protocolo de ejecución y checkpoints

### Dónde para

**Una tarea = un checkpoint.** Al terminar cada tarea:

1. Corré la Definition of Done completa del §1.2.
2. Commiteá con el mensaje indicado en la tarea (uno por tarea, nunca agrupados).
3. Marcá la casilla en la tabla del §6 con el hash.
4. **Pará y reportá.** No sigas con la siguiente por iniciativa propia.

El reporte son 4 líneas, no un ensayo: qué reproducía el problema antes, qué cambiaste,
cuántos tests hay ahora y si algo quedó raro.

**Excepción**: si una tarea "no reproduce", anotala en §6 y seguí con la siguiente sin
esperar — no tiene sentido parar por una tarea que no existía.

### Cómo se le pide (prompts para copiar y pegar)

**Una sola tarea:**

```
Leé openspec/changes/platform-hardening-2026-09/WORKPLAN.md, secciones §0.1, §1 y la de la
tarea <ID>. Ejecutá SOLO la tarea <ID>.

Reglas:
- Hacé primero la "Verificación previa obligatoria". Si el problema no reproduce, no toques
  código: anotalo en §6 y decímelo.
- No re-audites el proyecto ni busques otros bugs: el análisis ya está hecho en el archivo.
- No lances subagentes. La tarea ya tiene los archivos y las líneas: leé esos.
- No leas openspec/decisions.md completo (son >1000 líneas): grep a la sección puntual.
- Al terminar: DoD del §1.2, commit con el mensaje de la tarea, casilla marcada en §6, y pará.
```

**Varias tareas sueltas:**

```
Leé openspec/changes/platform-hardening-2026-09/WORKPLAN.md, secciones §0.1, §1 y las de las
tareas <ID>, <ID> y <ID>. Ejecutá esas tareas en ese orden, parando y reportando entre cada
una. Mismas reglas que arriba: verificación previa por tarea, un commit por tarea, sin
subagentes, sin re-auditar.
```

**Un workflow entero** (grupo de tareas ya agrupadas por objetivo):

```
Leé openspec/changes/platform-hardening-2026-09/WORKPLAN.md, secciones §0.1, §1 y el
WORKFLOW <N> completo. Ejecutá todas sus tareas en el orden en que aparecen, parando y
reportando después de cada una. Mismas reglas: verificación previa por tarea, un commit por
tarea, sin subagentes, sin re-auditar.
```

Los workflows de este archivo: **1** = crashes y bloqueo de tienda (§3) · **2** = robustez de
red y contrato (§4) · **3** = sostenibilidad (§5).

### Economía de tokens (importante)

- **Una sesión nueva por workflow, no por tarea ni por todo.** El contexto de la sesión que
  generó este archivo no aporta nada a la ejecución y se paga en cada mensaje.
- **Sin subagentes.** El archivo ya trae archivo, línea, causa raíz y trampas.
- **`openspec/decisions.md` supera las 1000 líneas.** Leerlo entero por costumbre es el gasto
  más grande y más evitable de este repo. Grep a la sección puntual.
- El commit por tarea es lo que permite tirar el contexto y arrancar limpio: el estado del
  trabajo vive en git y en la tabla del §6, no en la conversación.

---

## 1. Contexto del proyecto (lo mínimo indispensable)

`TekoApp-Frontend-Mobile` es la app Flutter (iOS + Android, un solo codebase) de TekoApp, un
marketplace paraguayo que conecta clientes que piden servicios del hogar/profesionales con los
profesionales que los prestan. Un mismo usuario opera como cliente o como profesional con la
misma cuenta (no hay apps separadas por rol).

Stack: Flutter 3 · Riverpod (`FutureProvider`/`AsyncNotifier`, un provider por operación de
servidor) · go_router (con guards de sesión y de "modo profesional") · dio (interceptors:
Bearer, refresh-en-401, unwrap del envelope, consentimiento-en-403).

Arquitectura por dominio, espejo del patrón de `TekoApp-Frontend-Web`:
`lib/features/<dominio>/{data,providers,models,widgets}/` + `lib/core/` (infra compartida) +
`lib/shared/widgets/` (primitivos).

**Sin BFF**: a diferencia de Web, esta app habla directo con el backend NestJS
(`TekoApp-Backend`) y el secreto Basic Auth de cliente vive en el binario. Limitación conocida
y documentada.

Estado al momento de esta auditoría: rama `audit/2026-09-04` sobre `develop` en `4be1343`,
413 tests en verde, fases 0001–0017 implementadas.

**Dato de contexto que enmarca todo**: siguen abiertos cuatro checkpoints de dispositivo real
(FCM en dos dispositivos, instalación de release firmado, integración de los 3 repos, firma de
contrato punta a punta). Buena parte de la app solo corrió contra `flutter test` y mocks,
nunca contra un backend vivo en un teléfono real. Los bugs del Workflow 1 son exactamente del
tipo que ese hueco deja pasar.

### 1.1 Convenciones NO negociables

1. **Los commits NUNCA llevan `Co-Authored-By`, ni referencia a Claude, a un modelo o a IA.**
   Autoría exclusiva de `josepanz`.
2. **Conventional Commits en español** (`fix:` / `feat:` / `refactor:` / `test:` / `docs:` /
   `chore:` / `ci:` / `build:`), porque semantic-release lee los prefijos.
3. **Nunca commitear directo a `develop`/`qa`/`master`.** Todo va en `audit/2026-09-04`.
4. **`referenceId` (UUID) en rutas y estado de UI, nunca el `id` interno.**
5. **`avatarKey` se persiste, `avatarUrl` no** — es una URL presignada de S3 que expira en
   900s. Mismo criterio para cualquier `fileKey` de portafolio/documentos.
6. **Cero strings hardcodeados en widgets** — todo texto visible sale de `l10n`
   (`lib/l10n/{es,en}.arb` + `flutter gen-l10n`). Ver `.claude/rules/i18n.md`.
7. **Un provider por operación de servidor**, nunca uno que mezcle 3 mutaciones.
8. **Transiciones de estado esperan 409**: el backend usa `updateMany` condicional; la UI
   maneja el conflicto con mensaje claro, nunca un error genérico.
9. **Un listado vacío es 200 con `[]`, nunca 404** — no tratar "sin resultados" como error.
10. Tests: `mocktail`, patrón AAA, nombres en español describiendo comportamiento.

### 1.2 Definition of Done global (aplica a TODA tarea)

Ninguna tarea está terminada hasta que todo esto pase:

```bash
cd C:\workspace\TekoApp-Frontend-Mobile
flutter gen-l10n                                    # si tocaste .arb
flutter analyze                                     # 0 issues
dart format --output=none --set-exit-if-changed .   # sin cambios pendientes
flutter test                                        # 413+ tests, TODOS en verde
```

> **`dart format` es un gate real del CI y ya rompió el pipeline una vez** (fase 0016: analyze
> y tests en verde, CI en rojo por formato). Corrélo localmente **siempre** antes de commitear.

Si un test existente se rompe: **no lo ajustes para que pase.** Entendé por qué primero. Si el
test pineaba comportamiento correcto, tu cambio está mal.

---

## 2. Inventario de hallazgos

Severidad: **CRÍTICO** = crashea la app o bloquea publicación en tienda · **ALTO** = pérdida de
funcionalidad o riesgo real · **MEDIO** = bug con workaround · **BAJO/ESTILO** = calidad.

| ID | Sev | Área | Síntoma en una línea |
|---|---|---|---|
| B-01 | CRÍTICO | contrato | Una reseña anónima en una lista pública crashea la pantalla entera |
| B-02 | CRÍTICO | iOS | Tocar "Tomar foto" mata la app en iOS y bloquea la submission |
| B-03 | MEDIO | assets | Foto de portafolio con URL vencida muestra el ícono roto de Flutter |
| B-04 | ALTO | i18n/UX | 21 pantallas muestran un error fijo en español y sin botón de reintentar |
| M-01 | MEDIO | sesión | Dos 401 simultáneos disparan dos refresh y pueden desloguear al usuario |
| M-02 | MEDIO | red | Sin retry: un paquete perdido falla el request, con hasta 90s de spinner mudo |
| M-03 | MEDIO | realtime | El socket de ubicación no reconecta ni avisa cuando se cae |
| M-04 | ALTO | contrato | Sin codegen desde swagger: cada modelo a mano, nada detecta un drift |
| M-05 | BAJO | contrato | `Payment.fromJson` descarta campos que el backend sí devuelve |
| M-06 | ALTO | robustez | Un 403 de consentimiento que no se puede satisfacer cuelga la app sin salida |
| M-07 | ALTO | contrato | Solo auth lleva `/v1`; el resto de los endpoints versionados da 404 |
| I-01 | CRÍTICO | legal | No hay borrado de cuenta (Apple 5.1.1(v), Play, Ley PY 6534/2020) |
| I-02 | MEDIO | seguridad | Sin `--obfuscate`: el secreto de cliente sale con `strings` del APK |
| I-03 | MEDIO | soporte | Un usuario con un pago fallido no tiene ningún canal in-app |
| I-04 | BAJO | notif. | Sin preferencias de notificación ni bandeja in-app |
| I-05 | BAJO | UX | Sin login biométrico (el login nonce+RSA es fricción alta) |
| E-01 | ESTILO | design system | `accent500` derivó 2 unidades hex del ancla de marca |

**Descartados explícitamente (auditados y NO son bugs — no los "arregles"):**

- **Paridad `es.arb`/`en.arb`: está limpia**, 383/383 claves. La deuda real de i18n es B-04
  (strings hardcodeados en un widget compartido), no el catálogo.
- **No hay colores hardcodeados en `lib/features/**`** — la derivación desde el tema generado
  es correcta en toda la capa de features.
- **`response.data!` sin guard en ~15 repositorios NO es un bug hoy**: el `EnvelopeInterceptor`
  garantiza `data` en cualquier 2xx. Es frágil ante una regresión del backend, pero no hay
  nada que arreglar sin cambiar el contrato del interceptor. No lo toques por las dudas.
- **"Online-only" sigue siendo la decisión correcta** — no agregues `connectivity_plus` ni una
  capa offline. Lo que falta es copy de error decente (B-04), no arquitectura offline.
- El timeout de 90s de `api_client.dart` **no es un descuido**: está tuneado para el cold start
  real del free tier de Render (~63s medidos el 2026-09-01). No lo bajes sin datos nuevos.

---

## 3. WORKFLOW 1 — Crashes garantizados y bloqueo de tienda (hacer primero)

**Objetivo**: que la app no pueda crashear por un dato normal del backend ni por tocar un
botón que ya existe, y que se pueda publicar en la App Store.

**Por qué primero**: B-01 y B-02 son crashes reproducibles con uso normal, no casos borde.
B-02 además es bloqueante de submission.

---

### B-01 · CRÍTICO · Una reseña anónima crashea la lista de reseñas

**[VERIFICADO A MANO]** (`rating.dart:39-40` contra `rating-detail.response.dto.ts:24-26,34-36`)

**Archivos**: `lib/features/ratings/models/rating.dart` (líneas 39-40 en `fromJson`, y las
declaraciones `final int userId;` / `final int professionalId;` más arriba).

**Síntoma**: abrir la lista pública de reseñas de un profesional que tenga **al menos una
calificación anónima** lanza `type 'Null' is not a subtype of type 'int'` y tumba la pantalla
entera. No es un caso borde: `isAnonymous` es una opción normal del producto.

**Causa raíz**: el modelo castea a `int` no-nullable dos campos que el backend documenta
explícitamente como nullables:

```dart
userId: json['userId'] as int,
professionalId: json['professionalId'] as int,
```

El DTO del backend (`TekoApp-Backend/src/api/ratings/dtos/response/rating-detail.response.dto.ts`)
declara `userId!: number | null` y `professionalId!: number | null` con `nullable: true` y la
descripción *"null cuando `isAnonymous=true` y quien consulta no es el [autor]"*. Web, que
genera sus tipos del OpenAPI, los tipa bien (`number | null`); Mobile los escribe a mano y
nadie detecta la divergencia hasta el runtime. Es la primera materialización concreta de M-04.

**Verificación previa obligatoria** — escribí primero un test que falle:

```dart
// test/features/ratings/models/rating_test.dart (crear si no existe)
// Hoy lanza; después del fix debe parsear con userId/professionalId en null.
final json = {
  'id': 1,
  'referenceId': 'r-1',
  'userId': null,
  'professionalId': null,
  'type': 'CLIENT_TO_PROFESSIONAL',
  'rating': 5,
  'review': 'Excelente',
  'isAnonymous': true,
  'isActive': true,
  'createdAt': '2026-09-01T10:00:00.000Z',
};
Rating.fromJson(json);   // hoy: type 'Null' is not a subtype of type 'int'
```

**Cambio**:

1. `final int? userId;` y `final int? professionalId;` en las declaraciones.
2. Quitar `required` de esos dos parámetros del constructor.
3. En `fromJson`: `json['userId'] as int?` / `json['professionalId'] as int?`.
4. Actualizá el docstring de la clase: hoy dice *"son el Int interno crudo"*; agregá que son
   `null` cuando la calificación es anónima y quien consulta no es el autor.
5. Grepeá consumidores antes de dar por cerrado: al 2026-09-04 **no hay ninguno fuera del
   propio modelo** (`professional_rating_stats_screen.dart:39` tiene un `professionalId`
   propio, de otro origen — no confundir). Si aparece alguno, manejá el `null` ahí.

**Tests a agregar** (`test/features/ratings/models/rating_test.dart`):

- Reseña anónima (`userId`/`professionalId` en `null`) parsea sin lanzar.
- Reseña no anónima parsea con los dos ids presentes (no-regresión).
- Una lista mixta (una anónima + una normal) parsea entera.

**Criterios de aceptación**: los 3 tests nuevos en verde; los 413 existentes sin tocar.

**Commit**: `fix(ratings): aceptar userId y professionalId nulos en calificaciones anonimas`

---

### B-02 · CRÍTICO · iOS crashea al tocar "Tomar foto" y no se puede publicar

**[VERIFICADO A MANO]** (`ios/Runner/Info.plist:29-30` — solo hay una `UsageDescription`)

**Archivos**: `ios/Runner/Info.plist`.

**Síntoma**: en iOS, un profesional que toca "Tomar foto" para subir un documento o una foto de
portafolio **crashea la app al instante**. No es un permiso denegado con mensaje: iOS mata el
proceso cuando se accede a la cámara sin la clave de uso declarada. Además, la App Store
rechaza el binario en review por el mismo motivo.

**Causa raíz**: `Info.plist` declara **únicamente** `NSLocationWhenInUseUsageDescription`
(líneas 29-30), pero `ImageSource.camera` se usa en dos lugares:

- `lib/features/professional_documents/widgets/upload_document_sheet.dart:155`
- `lib/features/professional_portfolio/widgets/upload_portfolio_item_sheet.dart:119`

Ambos sheets ofrecen además `ImageSource.gallery`.

**Verificación previa obligatoria**:

```bash
grep -n "UsageDescription" ios/Runner/Info.plist       # hoy: solo NSLocationWhenInUse
grep -rn "ImageSource.camera" lib/                      # hoy: 2 resultados
```

**Cambio**: agregar a `ios/Runner/Info.plist`, con texto explicativo real (usá el de ubicación
como modelo de tono — está bien redactado, dice para qué sirve, no es boilerplate):

- `NSCameraUsageDescription` — por qué la app usa la cámara (subir documentos de verificación y
  fotos de trabajos realizados).
- `NSPhotoLibraryUsageDescription` — por qué accede a la galería (elegir esas mismas fotos
  desde el carrete).

**Criterios de aceptación**: las dos claves presentes con texto en español explicando el uso
real; `flutter analyze` y la suite siguen en verde (el cambio es solo de plist, no debería
afectar nada más).

**Verificación adicional que NO podés hacer vos**: probar en un dispositivo/simulador iOS real
que la cámara abre. Anotalo como pendiente para José en el reporte de checkpoint.

**Commit**: `fix(ios): declarar el uso de camara y galeria en Info.plist`

---

### B-03 · MEDIO · Foto de portafolio con URL vencida muestra el ícono roto

**[VERIFICADO A MANO]** (los 2 sin `errorBuilder`; los 2 de referencia sí lo tienen)

**Archivos**:
- `lib/features/professional_portfolio/widgets/public_portfolio_section.dart:72-77`
- `lib/features/professional_portfolio/widgets/my_portfolio_screen.dart:100-105`
- Referencia correcta: `lib/shared/widgets/teko_avatar.dart:49-53` y
  `lib/features/service_progress/widgets/progress_timeline.dart:205-209`.

**Síntoma**: las fotos de portafolio se resuelven a URLs presignadas de S3 que expiran a los
900s. Si la pantalla queda abierta más que eso (o la resolución falla), `Image.network`
renderiza el ícono de imagen rota de Flutter en vez de un placeholder.

**Causa raíz**: las dos ramas `AsyncData(:final value) => Image.network(value, ...)` de
portafolio **no pasan `errorBuilder`**, aunque los dos widgets hermanos del repo sí lo hacen.
Es una inconsistencia introducida al escribir la feature de portafolio, no una decisión.

**Verificación previa obligatoria**:

```bash
grep -n "Image.network" -A 6 lib/features/professional_portfolio/widgets/*.dart | grep -c errorBuilder
# hoy: 0
```

**Cambio**: extraé un widget compartido en `lib/shared/widgets/` (sugerido:
`resolved_network_image.dart`) que encapsule el patrón completo *"resolver URL presignada →
`Image.network` → placeholder ante error o mientras carga"*, y usalo en los dos widgets de
portafolio.

Justificación de extraer en vez de parchear dos lugares: el patrón está duplicado casi textual
en **cuatro** archivos (los dos de portafolio, `teko_avatar`, `progress_timeline`). Un widget
compartido cierra el hueco en un solo lugar y evita que el quinto vuelva a olvidarlo.

**No migres `teko_avatar` ni `progress_timeline` en esta tarea** — ya funcionan y tienen tests
propios; migrarlos es un refactor aparte con su propio riesgo. Dejá anotado en el docstring del
widget nuevo que son candidatos a migrar después.

**Cuidado con los tests**: los tests de `my_portfolio_screen` overridean
`portfolioFileUrlProvider` con un `Completer` que nunca resuelve, justamente para no renderizar
`Image.network` (ver el comentario en `my_portfolio_screen_test.dart` y el criterio de
`teko_avatar_test.dart`: no vale la pena mockear la carga de imagen de red). Mantené ese
enfoque: el placeholder estático de la rama `_` no debe cambiar a un spinner animado, o
`pumpAndSettle()` deja de asentarse.

**Tests a agregar**: un test de widget del componente nuevo — dado un `errorBuilder`
disparado, renderiza el placeholder y no lanza.

**Commit**: `fix(portfolio): degradar con placeholder cuando la URL presignada expira`

---

### B-04 · ALTO · 21 pantallas muestran un error fijo en español y sin reintentar

**[VERIFICADO A MANO]** (`async_state_view.dart`, strings en las ramas de error y vacío)

**Archivos**: `lib/shared/widgets/async_state_view.dart` (los dos strings por defecto), y los
dos llamadores que ni siquiera pasan `errorMessage`:
`lib/features/legal_consents/widgets/privacy_and_data_screen.dart` y
`lib/features/legal_consents/widgets/legal_consent_screen.dart`.

**Síntoma**: un error de red mientras se carga cualquier pantalla muestra
`'Ocurrió un error inesperado.'` — **en español aunque el dispositivo esté en inglés**, y **sin
ningún botón para reintentar**. El usuario queda en una pantalla muerta cuya única salida es
volver atrás y entrar de nuevo. Con el timeout de 90s (justificado, ver §2), puede haber estado
mirando un spinner minuto y medio antes de llegar a ese texto.

**Causa raíz**: `AsyncStateView` es el wrapper compartido de loading/error/vacío usado por 21
pantallas, y hardcodea sus dos textos por defecto:

```dart
errorMessage ?? 'Ocurrió un error inesperado.'
emptyMessage ?? 'No hay datos para mostrar.'
```

Viola la regla del repo *"cero strings hardcodeados en widgets"* (`.claude/rules/i18n.md`), y
al ser un widget compartido es la mayor fuente de copy sin traducir de la app. Las pantallas
que sí pasan `errorMessage` quedan traducidas por casualidad; las dos de legal_consents no lo
pasan y muestran el texto fijo.

**Verificación previa obligatoria**:

```bash
grep -n "Ocurrió un error inesperado\|No hay datos para mostrar" lib/shared/widgets/async_state_view.dart
grep -rn "AsyncStateView" lib/ | wc -l          # dimensiona el alcance
grep -n "errorMessage" lib/features/legal_consents/widgets/privacy_and_data_screen.dart
```

**Cambio**:

1. `AsyncStateView` pasa a recibir el `BuildContext` (ya lo tiene en `build`) y resolver sus
   defaults por `AppLocalizations.of(context)!` en vez de literales. Claves nuevas en
   `lib/l10n/es.arb` y `en.arb` (sugerido: `asyncStateGenericError`, `asyncStateEmpty`), y
   `flutter gen-l10n`.
2. Agregá un parámetro opcional `VoidCallback? onRetry`. Cuando venga, la rama de error
   muestra además un botón de reintentar (`TekoButton` variante `outline`, label desde `l10n`).
   Cuando no venga, se comporta exactamente como hoy — así ninguna de las 21 pantallas se rompe.
3. Cableá `onRetry` **solo** en las dos pantallas de legal_consents (invalidando su provider).
   Las otras 19 quedan igual: migrarlas es trabajo aparte, y hacerlo acá vuelve la tarea
   irrevisable.

**Tests a agregar** (`test/shared/widgets/async_state_view_test.dart`, crear si no existe):

- Estado de error sin `errorMessage` muestra el texto **traducido** (montar con `Locale('en')`
  y verificar que NO aparece el texto en español).
- Con `onRetry`, aparece el botón y tocarlo invoca el callback.
- Sin `onRetry`, no aparece ningún botón (no-regresión de las 19 pantallas restantes).
- Estado vacío sin `emptyMessage` muestra el texto traducido.

**Criterios de aceptación**: ningún literal de UI queda en `async_state_view.dart`; las 21
pantallas siguen compilando sin cambios; suite en verde.

**Commit**: `fix(ui): traducir los textos por defecto de AsyncStateView y permitir reintentar`

---

## 4. WORKFLOW 2 — Robustez de red y contrato

**Objetivo**: que la app se comporte razonablemente en una red móvil real — que es una
condición que esta app **nunca fue probada de verdad** (ver los 4 checkpoints abiertos del §1).

---

### M-01 · MEDIO · Dos 401 simultáneos disparan dos refresh y pueden desloguear

**[VERIFICADO A MANO]** (`lib/core/auth/refresh_token_interceptor.dart`, la limitación está
escrita en el docstring de la clase)

> Nota: la auditoría delegada ubicó este archivo en `lib/core/api_client/`. **Está en
> `lib/core/auth/`.** Confirmá la ruta antes de abrir.

**Síntoma**: dos requests en vuelo que expiran a la vez disparan dos `POST /auth/refresh-token`
en paralelo. Si el backend rota o invalida el refresh al usarlo, el segundo falla, el
interceptor limpia el `accessToken` guardado, y el usuario queda deslogueado a mitad de sesión
aunque el primer refresh haya salido bien.

**Causa raíz**: es una simplificación **conocida y documentada**, no un descuido — el docstring
de `RefreshTokenInterceptor` dice literalmente *"no coordina refrescos concurrentes (varios 401
a la vez disparan varios refresh en paralelo) — aceptable para el volumen de requests de esta
app hoy"*. Lo que cambió es que ahora hay pantallas que disparan varios providers a la vez.

**Verificación previa obligatoria**: test que falle primero — dos requests que devuelven 401
simultáneamente producen **dos** llamadas a `/auth/refresh-token` con el `Dio` mockeado.

**Cambio**: un `Completer<void>?` a nivel de instancia del interceptor. El primer 401 crea el
completer y hace el refresh; los siguientes, mientras haya uno en vuelo, esperan ese mismo
completer en vez de disparar el suyo, y después reintentan su request original. Limpiá el
completer en `finally`, pase lo que pase, o dejás el interceptor trabado para siempre.

Cuidado: `_excludedPaths` (login/nonce/public-key/refresh-token) tiene que seguir saliendo
temprano — no metas el gate del completer antes de esa comprobación o un 401 del propio login
se queda esperando un refresh que nunca va a pasar.

**Tests**: dos 401 concurrentes → un solo `POST /auth/refresh-token`, ambos requests
reintentados; refresh que falla → ambos reciben el error original y el token se limpia una sola
vez; no-regresión: un 401 aislado sigue funcionando igual.

**Commit**: `fix(auth): coordinar refrescos de token concurrentes con un solo request en vuelo`

---

### M-02 · MEDIO · Sin retry: un paquete perdido falla el request entero

**Archivos**: `lib/core/api_client/api_client.dart` (`_buildDefaultDio`, ~líneas 47-61).

**Síntoma**: en una red móvil real, un corte momentáneo falla el request completo sin ningún
reintento. El usuario ve un error y tiene que repetir la acción a mano.

**Causa raíz**: `BaseOptions` solo define `connectTimeout`/`receiveTimeout` de 90s. No hay
`dio_smart_retry` ni equivalente en `pubspec.yaml`.

> **No toques los 90s.** Están justificados con una medición real (cold start del free tier de
> Render, ~63s el 2026-09-01) y el comentario del código lo documenta. Bajarlos rompe el primer
> arranque de la app.

**Verificación previa obligatoria**: confirmá que no hay política de retry
(`grep -rn "retry" pubspec.yaml lib/core/api_client/`).

**Cambio**: agregar retry con backoff exponencial acotado **solo a métodos idempotentes**
(`GET`/`HEAD`) y solo a errores de conexión/timeout — nunca a un 4xx, y **nunca a un `POST`**
(un POST de pago o de calificación reintentado a ciegas duplica el efecto). Máximo 2 reintentos.

Decisión a tomar y documentar en el commit: `dio_smart_retry` como dependencia nueva vs. un
interceptor propio de ~40 líneas. Preferí el interceptor propio si la dependencia arrastra
transitivas — este repo ya tuvo una rotura real por una dependencia (`permission_handler` y
`compileSdk`, fase 0015).

**Tests**: `GET` que falla por timeout y luego responde → se reintenta y devuelve el dato; `GET`
que falla 3 veces → propaga el error; `POST` que falla → **no** se reintenta; 4xx → no se
reintenta.

**Commit**: `feat(network): reintentar requests idempotentes ante fallos transitorios`

---

### M-03 · MEDIO · El socket de ubicación no reconecta ni avisa

**Archivos**: `lib/core/realtime/locations_socket_service.dart` (~38-56, `connect()`).

**Síntoma**: si la conexión se cae (blip de red, o el JWT de 15 minutos vence a mitad de
sesión), el socket queda muerto en silencio: la ubicación del profesional deja de compartirse,
sin feedback en la UI ni reintento.

**Causa raíz**: `connect()` no registra handlers de `connect_error` ni `disconnect`, ni tiene
lógica de reconexión con token fresco.

**Verificación previa obligatoria**: leé `connect()` y confirmá que no hay `onConnectError`/
`onDisconnect`. Si ya los tiene, **no reproduce** — anotalo y seguí.

**Cambio**: registrar `connect_error` y `disconnect`; ante desconexión, intentar reconectar con
un token fresco (backoff acotado, con tope de reintentos) y exponer un estado observable que la
UI pueda mostrar ("reconectando…"). No reintentes infinito: si el refresh de token falla, cortá
y dejá el estado en error.

**Tests**: con el socket mockeado, un `disconnect` dispara un intento de reconexión; agotados
los reintentos, el estado queda en error.

**Commit**: `fix(realtime): reconectar el socket de ubicacion con token fresco al caerse`

---

### M-04 · ALTO · Sin codegen desde swagger: cada modelo a mano

**Archivos**: todo `lib/features/*/models/*.dart`, `pubspec.yaml`, CI.

**Síntoma**: no hay ningún mecanismo que detecte una divergencia entre lo que el backend
devuelve y lo que el modelo Dart espera. B-01 es la primera vez que eso explotó en runtime;
no va a ser la última.

**Causa raíz estructural**: Web genera sus tipos del OpenAPI real
(`pnpm generate:api-types` → `types.generated.ts`) y por eso se auto-corrige: si el backend
cambia un DTO, `pnpm check:types` falla en CI. Mobile escribe **cada modelo a mano**, así que
un drift solo se descubre cuando un usuario abre la pantalla afectada.

**Esta tarea es de diseño, no de ejecución mecánica.** Antes de escribir código, evaluá y
proponé: `openapi_generator` vs `swagger_dart_code_generator` vs un script propio que genere
solo los `fromJson`. Criterios: no romper los modelos actuales de golpe (son ~30 y todos tienen
tests), poder adoptarlo dominio por dominio, y que el CI falle si lo generado difiere de lo
commiteado.

**Entregable de esta tarea**: una propuesta escrita en
`openspec/changes/platform-hardening-2026-09/CODEGEN.md` con la opción elegida, el plan de
migración incremental y un dominio migrado como prueba de concepto (sugerido: `ratings`, que ya
tocás en B-01). **No migres los 30 modelos.**

**Commit**: `docs(contrato): proponer codegen de modelos desde el OpenAPI del backend`

---

### M-05 · BAJO · `Payment.fromJson` descarta campos que el backend devuelve

**Archivos**: `lib/features/payments/models/payment.dart` (~66-92).

El modelo ignora `isRecurring`, `paymentDetails`, `metadata`, `processedAt`/`paidAt`/`failedAt`,
`failureReason`, `externalTransactionId`. No es un crash: bloquea construir una pantalla de
recibo o de disputa sin volver a tocar el modelo.

> **Ojo con `professionalNetAmount`**: el backend lo expone pero **nunca lo escribe** (siempre
> viaja `null`). No lo agregues al modelo ni lo muestres hasta que el backend lo resuelva —
> ver la tarea D-03 del WORKPLAN de `TekoApp-Backend`.

**Hacé esta tarea solo cuando exista una pantalla que necesite los campos.** Agregar campos
"por si acaso" a un modelo sin consumidor es deuda, no mejora. Anotala como diferida en §6 si
no hay pantalla pedida.

**Commit** (si se hace): `feat(payments): exponer los campos de detalle que el backend ya devuelve`

---

### M-06 · ALTO · Un `403 CONSENT_REQUIRED` que no se puede satisfacer cuelga la app para siempre

**[VERIFICADO A MANO]** (reproducido en un Samsung SM-G990B2 real contra el backend local,
2026-09-06: el botón de subir al portafolio quedó girando indefinidamente, sin error, sin crash y
sin pantalla de consentimientos)

**Archivos**:
- `lib/features/legal_consents/providers/consent_required_bridge_provider.dart` (el `Completer`)
- `lib/features/legal_consents/widgets/consent_gateway.dart` (`_handleConsentRequired`)
- `lib/core/api_client/consent_required_interceptor.dart` (quien espera el `Future`)

**Síntoma**: ante un `403 CONSENT_REQUIRED`, la app se queda cargando **para siempre**. No muestra
error, no crashea, no ofrece salida: el spinner del botón gira indefinidamente y la única forma de
salir es matar la app. Peor que un error, porque el usuario no tiene forma de saber qué pasó.

**Causa raíz**: `ConsentRequiredInterceptor` hace `await _onConsentRequired()` y queda esperando un
`Completer<bool>` que **nadie garantiza que se complete**. Hay tres caminos por los que el
`resolve()` nunca ocurre, y ninguno tiene red de contención:

1. **`ConsentGateway._handleConsentRequired` sale temprano sin resolver**:
   ```dart
   if (_isShowingConsentFlow || !mounted) return;   // ← no llama resolve()
   ```
2. **El `push` va con `unawaited`**: si `GoRouter.push('/legal/consentimiento')` lanza, la
   excepción se traga y tampoco se resuelve.
3. **`_controller` es `StreamController.broadcast()`**: si el evento se emite y no hay listener en
   ese instante exacto, se descarta silenciosamente (un broadcast no bufferea).

Además **no hay timeout en ningún lado**, así que cualquiera de los tres deja el `Future` colgado
de forma permanente.

**Cómo se descubrió (contexto que importa)**: la base de prueba tenía `legal_document_versions`
con **0 filas**, así que el guard del backend devolvía `CONSENT_REQUIRED` de forma permanente y la
pantalla de aceptación no tenía nada que ofrecer — un estado imposible de resolver desde la UI.
Ese escenario de datos es real y volverá a pasar (ver T-04 del WORKPLAN de `TekoApp-Backend`), así
que la app tiene que degradar con dignidad en vez de colgarse.

**Verificación previa obligatoria** — escribí primero un test que falle
(`test/core/api_client/consent_required_interceptor_test.dart`, extender el existente si lo hay):

```dart
// Un 403 CONSENT_REQUIRED cuyo flujo de consentimiento NUNCA resuelve debe terminar en error,
// no quedar pendiente para siempre. Hoy este test queda colgado hasta el timeout de `flutter test`.
final interceptor = ConsentRequiredInterceptor(dio, () => Completer<bool>().future);
// ... disparar el onError con un 403 + errorCode CONSENT_REQUIRED
// esperado tras el fix: el handler recibe un error dentro de un plazo acotado
```

**Cambio** — las tres cosas, no una:

1. **Timeout en el interceptor**: `await _onConsentRequired().timeout(<D>, onTimeout: () => false)`.
   Elegí la duración y **justificala en un comentario**; 60s es un punto de partida razonable
   (suficiente para que una persona lea y acepte, acotado para no colgar la app). Al vencer, seguir
   por `handler.next(err)` — el usuario ve el error real del backend, que es honesto.
2. **`resolve()` en TODAS las salidas de `_handleConsentRequired`**: el `return` temprano por
   `!mounted` / `_isShowingConsentFlow` debe llamar `resolve(false)` antes de salir, y el `push`
   debe ir en `try/catch/finally` que resuelva pase lo que pase (hoy `unawaited` se come la
   excepción).
3. **No perder el evento**: hoy `requestConsentAndWait` emite en un broadcast sin verificar que
   haya alguien escuchando. Agregá el guard: si `!_controller.hasListener`, completar el
   `Completer` con `false` inmediatamente en vez de emitir al vacío.

**Trampa**: no rompas la deduplicación que ya existe y está bien pensada — dos requests que fallan
con `CONSENT_REQUIRED` casi a la vez comparten el MISMO `Completer` a propósito, para no abrir dos
pantallas de aceptación. El timeout tiene que resolver ese completer compartido una sola vez (ojo
con `complete()` sobre un completer ya completado: lanza `StateError`).

**Tests a agregar**:
- El flujo de consentimiento nunca resuelve → el request falla por timeout, no queda colgado.
- `resolve(false)` (usuario canceló) → propaga el error original, sin reintento.
- `resolve(true)` → reintenta el request original (no-regresión del camino feliz).
- Sin listener en el bridge → el `Future` se completa en `false` en vez de colgarse.
- Dos requests concurrentes con `CONSENT_REQUIRED` → un solo evento emitido, ambos resueltos juntos
  (no-regresión de la deduplicación).

**Criterios de aceptación**: ningún camino deja un `Completer` sin resolver; la suite completa en
verde sin que ningún test dependa del timeout global de `flutter test` para terminar.

**Commit**: `fix(consentimientos): evitar que un 403 CONSENT_REQUIRED cuelgue la app sin salida`

---

### M-07 · ALTO · Solo las llamadas de auth llevan el prefijo `/v1`; el resto de los endpoints versionados sigue roto

**[VERIFICADO A MANO]** (confirmado contra el backend real el 2026-09-05: sin `/v1` la ruta
devuelve 404, con `/v1` responde)

**Archivos**: `lib/features/profile/data/profile_repository.dart` (`/uploads/avatar`), y todo
`lib/features/*/data/*.dart` que pegue a `uploads/`, `roles/`, `users/` u `onboarding/`.

**Síntoma**: el backend expone **algunos** controllers con `@Version('1')` y otros sin versionar.
Nest sirve los versionados **solo** bajo `/tekoapp-backend/api/v1/...`; sin ese segmento devuelve
404. El fix de hoy (commit `c653576`) cubrió únicamente `/auth/*` y `/onboarding`, por decisión
explícita de alcance. **Todo lo demás que esté versionado sigue roto y nadie lo detecta**, porque
la suite mockea Dio y nunca pega a un backend real.

**Mapa verificado el 2026-09-05** (releelo contra el backend antes de accionar, puede haber
cambiado):

| Versionados (`/v1` obligatorio) | Sin versionar (sin `/v1`) |
|---|---|
| `auth/*`, `onboarding`, `uploads/*`, `roles/*`, `users/*` | `professionals/*`, `services/*`, `locations/*`, `payments/*`, `ratings/*`, `promotions/*`, `notifications/*` |

**Verificación previa obligatoria** — **no confíes en la tabla de arriba**, regenerala vos:

```bash
# En TekoApp-Backend, con el server levantado, mirá qué rutas quedan mapeadas con "(version: 1)":
grep -E "Mapped \{.*\}" <log-de-arranque> | grep "version: 1"
# Y del lado Mobile, listá todos los paths que se piden hoy:
grep -rnoE "'/[a-z0-9/_-]+'" lib/features/*/data/*.dart lib/core/ | sort -u
```

Cruzá ambas listas. Un endpoint que Mobile pide sin `/v1` y el backend expone con `version: 1` es
un 404 garantizado en runtime.

**Cambio**: agregar `/v1` **solo** a los paths cuyo controller esté versionado. **No lo agregues
globalmente en el `baseUrl`**: rompería todos los endpoints no versionados, que son la mayoría.

**Decisión de diseño a tomar y documentar en el commit**: hoy el prefijo va hardcodeado por
call-site (así quedó en `auth_repository.dart`). Si al cruzar las listas aparecen muchos más
call-sites, evaluá centralizarlo (una constante compartida, o un interceptor que sepa qué prefijos
versionar) — pero **no inventes una abstracción para dos casos**. Elegí según el número real que te
dé la verificación previa.

**Trampa**: `RefreshTokenInterceptor._excludedPaths` compara paths exactos. Si cambiás un path que
esté en esa lista, actualizá la lista en el mismo commit o el interceptor deja de excluirlo.

**Tests**: actualizar los mocks de Dio de cada repositorio tocado para esperar el path nuevo (los
tests son la única red que tenés acá, porque el path viaja como string).

**Nota de fondo**: esto es un síntoma de que **la política de versionado de la API no existe** —
ver I-04 del WORKPLAN de `TekoApp-Backend`. Mientras no se defina, esta clase de bug va a volver.
No cierres I-04 como "documentación" sin que incluya qué controllers deben versionarse.

**Commit**: `fix(api): prefijar /v1 en el resto de los endpoints versionados del backend`

---

## 5. WORKFLOW 3 — Sostenibilidad (specs y decisiones, poco código)

Estas tareas **no** son mecánicas. Requieren decisiones de producto/legales. Si las ejecuta un
modelo sin acceso a José, el entregable es la propuesta escrita, no la implementación.

---

### I-01 · CRÍTICO · No hay borrado de cuenta

**Síntoma**: no existe flujo de eliminación de cuenta ni en Mobile (`profile_screen.dart` solo
expone logout) ni en el backend. Apple lo exige in-app desde 2022 (Guideline 5.1.1(v)), Google
Play pide equivalente, y la Ley paraguaya 6534/2020 concede derecho de supresión.

**Bloqueado por backend**: necesita el endpoint que define la tarea I-01 del WORKPLAN de
`TekoApp-Backend` (qué se borra vs. qué se anonimiza — pagos y contratos tienen retención
legal; ventana de gracia; efecto sobre servicios en curso).

**Entregable de esta tarea en Mobile**: la spec de la pantalla y el flujo (confirmación de dos
pasos, qué se le explica al usuario sobre qué se borra y qué se conserva por ley, qué pasa si
tiene un servicio activo o un pago pendiente). Implementación cuando el endpoint exista.

**Commit**: `docs(cuenta): especificar el flujo de borrado de cuenta en la app`

---

### I-02 · MEDIO · Sin ofuscación: el secreto de cliente sale del APK

**Archivos**: `.github/workflows/build.yml`, `.github/workflows/release.yml`,
`lib/core/config/env.dart` (~17-27).

El secreto Basic Auth de cliente entra por `--dart-define` y queda como string plano en el
binario, extraíble con `strings` sobre el APK. `.claude/rules/auth.md` pidió decidir esto y
quedó documentado como limitación conocida, pero no se agregó ningún paso de ofuscación.

**Cambio**: agregar `--obfuscate --split-debug-info=<dir>` a los builds de release y archivar
los símbolos como artefacto del workflow (sin ellos no podés simbolizar un stacktrace de
producción).

**Sé honesto sobre lo que esto logra**: no elimina el riesgo — es inherente a no tener un BFF —
lo sube de trivial a molesto. Escribilo así en el commit y en `decisions.md`, no como si lo
resolviera.

**Verificación**: build de release real + `strings` sobre el APK, confirmando que el secreto ya
no aparece en claro.

**Commit**: `build(android): ofuscar el binario de release y archivar los simbolos`

---

### I-03 / I-04 / I-05 · Canal de soporte, preferencias de notificación, biométrico

Tres features nuevas, en orden de valor:

- **I-03 (MEDIO)**: hoy un usuario con un pago fallido o un profesional que no apareció **no
  tiene ningún camino dentro de la app** para contactar a nadie. Para un marketplace que mueve
  plata, es el hueco más grande de los tres.
- **I-04 (MEDIO)**: `lib/features/notifications/` es solo el gateway de token push. Falta
  pantalla de preferencias y bandeja in-app.
- **I-05 (BAJO)**: login biométrico (`local_auth`). El login nonce+RSA-OAEP es más fricción que
  el promedio móvil; mejora retención pero no arregla nada roto.

Cada una necesita su propia spec antes de código. No las agrupes.

---

### E-01 · ESTILO · `accent500` derivó del ancla de marca

`lib/design_system/tokens.generated.dart:45` — `accent500 = Color(0xFF19BEBB)` con un comentario
que admite *"~#17BEBB"*, mientras `primary500` sí clava `#28A745` exacto. La conversión
OKLCH→sRGB derivó 2 unidades hex. Imperceptible a la vista, inconsistente con el estándar de
"ancla exacta" del design system.

Arreglalo **solo si estás tocando ese archivo por otra razón**. No abras un commit para esto.

---

## 6. Tabla de seguimiento

| ID | Sev | Estado | Commit | Notas |
|---|---|---|---|---|
| B-01 | CRÍTICO | [x] | c78cd12 | |
| B-02 | CRÍTICO | [x] | 71a4fab | Verificación en device real queda para José |
| B-03 | MEDIO | [x] | 9f22f1f | |
| B-04 | ALTO | [x] | f7443f0 | |
| M-01 | MEDIO | [x] | 7d6c643 | |
| M-02 | MEDIO | [x] | 36632b1 | |
| M-03 | MEDIO | [x] | 99d4f59 | connectionState expuesto, sin consumidor en UI todavía (no hay pantalla que lo pida) |
| M-04 | ALTO | [x] | 11a1685 | Script propio (no openapi_generator/swagger_dart_code_generator); PoC en `ratings`, probado contra fixture local — ver CODEGEN.md |
| M-05 | BAJO | [x] | 957bbfb | Ejecutada por pedido explícito (no diferida). D-03 ya resuelto en backend: professionalNetAmount ya no es siempre null, se agregó |
| M-06 | ALTO | [x] | 08fa295 | |
| M-07 | ALTO | [x] | 88100d9 | Solo `uploads/*` (5 call-sites) — es lo único versionado que Mobile llama fuera de auth/onboarding |
| I-01 | CRÍTICO | [ ] | | Bloqueado por el endpoint del backend |
| I-02 | MEDIO | [x] | 1f31b43 | Solo release.yml (build.yml es --debug/--no-codesign, no distribuible); no elimina el secreto, ver decisions.md |
| I-03 | MEDIO | [x] | 96c3529 | Spec en openspec/specs/support-channel.md — bloqueada por backend, no implementada |
| I-04 | BAJO | [x] | 17ae9b3 | Spec en notification-preferences-and-inbox.md. Hallazgo: bandeja NO bloqueada por backend (API ya existe), pero ningún dominio dispara notificaciones todavía — gap de TekoApp-Backend |
| I-05 | BAJO | [x] | e96a907 | Spec en biometric-login.md. Hallazgo: hoy no hay fricción en apertura normal (sesión ya se restaura sola); biométrico solo ayuda post-logout explícito |
| E-01 | ESTILO | [x] | 7babcec | Commit propio por pedido explícito (no se estaba tocando el archivo por otra razón) |
