# Fase 0008 — Bitácora de trabajo ("paso a paso")

Spec de diseño, NO implementada todavía — feature 7 del backlog 2026-08-22
(`openspec/decisions.md`). Contrato de dominio: `openspec/specs/work-progress-log.md` (mobile),
`TekoApp-Backend/openspec/specs/work-progress-log.md` (backend).

## Antes de empezar

Leer `openspec/specs/work-progress-log.md` y el spec de backend completo. No hay spec de Web
dedicada para esta feature — ver la nota de alcance abierta ahí ("Decisión de alcance abierta para
José") antes de asumir que el staff no necesita ninguna visibilidad.

## Objetivo

El profesional documenta el avance de un `Service` `ACCEPTED`/`IN_PROGRESS` con entradas de
bitácora (nota + fotos), visibles en orden cronológico para el cliente dueño del servicio.

## Alcance

**Incluye**: pantalla de timeline dentro del detalle de servicio (ambos roles), formulario de
nueva entrada (profesional), corrección/eliminación de una entrada propia dentro de la ventana de
tiempo configurada por el backend.

**No incluye**: comentarios del cliente sobre una entrada puntual, geolocalización por entrada.

## Pantallas / flujos

`lib/features/service_progress/` (nuevo dominio, mismo patrón `data/providers/models/widgets`).

- `data/service_progress_api.dart` — `POST/GET/DELETE /services/:referenceId/progress`.
- `providers/service_progress_provider.dart` — `FutureProvider.family<List<ProgressEntry>,
  String>` (por `serviceReferenceId`) + un `AsyncNotifier` de mutación para crear/eliminar, con
  invalidación del listado tras cada mutación exitosa.
- `widgets/progress_timeline.dart` — widget embebido en la pantalla de detalle de servicio ya
  existente (`lib/features/services/widgets/service_detail_screen.dart`), no una ruta nueva de
  `go_router` — la bitácora es una sección del detalle, no una pantalla independiente.
  - Timeline vertical ordenada, cada entrada: fecha, nota, grid de fotos (tap para ampliar,
    reusar el visor de imágenes ya usado en fotos de `Service.images` si existe uno compartido en
    `shared/widgets/`).
  - Botón "Agregar avance" visible solo al profesional asignado y solo si el servicio está
    `ACCEPTED`/`IN_PROGRESS`.
  - Cada entrada propia dentro de la ventana de edición muestra un botón de eliminar; pasada la
    ventana, el backend responde 409 `EDIT_WINDOW_EXPIRED` — la UI debe directamente no ofrecer el
    botón si el timestamp local ya superó la ventana conocida (evitar el roundtrip fallido cuando
    es predecible), pero igual manejar el 409 con gracia si el reloj del dispositivo está desfasado.
- `widgets/add_progress_entry_sheet.dart` — bottom sheet con campo de nota (opcional) + selector de
  fotos (múltiples, hasta el máximo configurado — leer el límite real del backend si se expone en
  algún endpoint de config, o coordinarlo como constante documentada si no).

## Tareas

- [x] `data/`+`providers/`+`models/` de `service_progress`.
- [x] Sección de timeline embebida en el detalle de servicio (ambos roles) — `ProgressTimeline`,
      wired en `service_detail_screen.dart` cuando `service.professional != null`.
- [x] Formulario de nueva entrada con selector de fotos múltiple (`image_picker.pickMultiImage`).
- [x] Manejo de 409 (`ServiceProgressConflictFailure`, cubre tanto `EDIT_WINDOW_EXPIRED` como
      "servicio no está ACCEPTED/IN_PROGRESS") — mensaje del backend mostrado tal cual, no
      genérico.
- [ ] Validación `PROGRESS_LOG_REQUIRED` al completar un servicio — **no implementado en esta
      sesión**: `professional_services_screen.dart`/`service_transition_controller_provider.dart`
      (el flujo real de "completar") no fueron tocados; el error ya llegaría del backend como 400
      con mensaje claro (`ServiceFailure` genérico lo mostraría), pero no se agregó un mensaje
      específico ni un test para este caso puntual. Pendiente de una tarea chica aparte.
- [x] Traducir a es/en.
- [x] Tests: repositorio (7), controller (4), widget de la timeline (5) y del formulario (3) — 19
      tests nuevos, ver detalle en `openspec/decisions.md`.

## Corrección tras implementar (2026-08-27)

Igual que en el backend: las fotos NO se mandan en el mismo POST que crea la entrada. Se suben
antes, una por una, vía `POST /uploads/image` (mismo patrón ya usado por
`ProfileRepository.uploadAvatar` para el avatar) — `ServiceProgressRepository.createEntry` solo
recibe las keys ya subidas. También se agregó `resolvePhotoUrl(key)` (vía
`GET /uploads/presigned-url`) para poder renderizar las miniaturas de las fotos ya guardadas — esto
no estaba en la spec original, ninguna otra pantalla de mobile resolvía todavía una key de S3 a una
URL mostrable.

## Checkpoint de salida

- [x] Profesional agrega una entrada con fotos durante un servicio `IN_PROGRESS`, el cliente la ve
      en su propia pantalla sin recargar la app entera (`ref.invalidate` tras la mutación).
- [x] Eliminar una entrada dentro de la ventana de edición funciona; pasada la ventana, el mensaje
      de error es claro, no genérico — además, el botón de eliminar directamente no se muestra si
      `editWindowExpired` ya es `true` (calculado por el backend, ver spec).
- [ ] Si la categoría del servicio exige bitácora, intentar completarlo sin ninguna entrada
      muestra el mensaje `PROGRESS_LOG_REQUIRED` de forma clara antes de dejar completar — **no
      verificado, ver tarea pendiente arriba**.
- [ ] Checkpoint real contra un dispositivo/emulador Android con backend local corriendo — esta
      sesión solo verificó `flutter analyze`/`flutter test`, no probó la app corriendo de verdad
      (mismo límite ya documentado en `.claude/rules/test.md` para el resto del repo).

## Relación con otras features

Comparte el guard de consentimiento de `0012-data-and-image-consent.md` para las fotos subidas —
mismo manejo de `403 CONSENT_REQUIRED` que `0007`.
