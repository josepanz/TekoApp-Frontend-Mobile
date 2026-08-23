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

- [ ] `data/`+`providers/`+`models/` de `service_progress`.
- [ ] Sección de timeline embebida en el detalle de servicio (ambos roles).
- [ ] Formulario de nueva entrada con selector de fotos múltiple.
- [ ] Manejo de 409 `EDIT_WINDOW_EXPIRED` y de la validación `PROGRESS_LOG_REQUIRED` al intentar
      completar un servicio de una categoría que lo exige (mostrar el mensaje del backend, no un
      genérico — mismo criterio ya aplicado en la Fase 0004 a mensajes de error textuales).
- [ ] Traducir a es/en.
- [ ] Tests: provider (happy path, error, estado vacío "todavía no hay avances registrados"),
      widget test de la timeline y del formulario.

## Checkpoint de salida

- [ ] Profesional agrega una entrada con fotos durante un servicio `IN_PROGRESS`, el cliente la ve
      en su propia pantalla sin recargar la app entera (refetch al entrar a la pantalla).
- [ ] Eliminar una entrada dentro de la ventana de edición funciona; pasada la ventana, el mensaje
      de error es claro, no genérico.
- [ ] Si la categoría del servicio exige bitácora, intentar completarlo sin ninguna entrada
      muestra el mensaje `PROGRESS_LOG_REQUIRED` de forma clara antes de dejar completar.

## Relación con otras features

Comparte el guard de consentimiento de `0012-data-and-image-consent.md` para las fotos subidas —
mismo manejo de `403 CONSENT_REQUIRED` que `0007`.
