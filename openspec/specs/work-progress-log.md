# Spec: Bitácora de trabajo ("paso a paso")

Backend: `TekoApp-Backend/openspec/specs/work-progress-log.md`. Plan de fase:
`openspec/changes/0008-work-progress-log.md`.

## Modelo de dominio (ya definido en el backend, replicar el contrato tal cual)

- **ServiceProgressEntries**: `note` (opcional), `images[]` (S3 keys), `entryOrder` (secuencia
  dentro del `Service`) — creadas por el profesional asignado mientras el `Service` está
  `ACCEPTED`/`IN_PROGRESS`.
- `Category.requiresProgressLog`: si `true`, el backend rechaza `completeService` sin al menos una
  entrada activa (`400 PROGRESS_LOG_REQUIRED`).

## Flujos de UI esperados

1. Dentro del detalle de un `Service` (ambos roles): sección de timeline con las entradas
   ordenadas cronológicamente.
2. Profesional: botón "Agregar avance" (visible solo si es el asignado y el servicio está
   `ACCEPTED`/`IN_PROGRESS`) → nota opcional + fotos.
3. Corrección: el autor puede eliminar su propia entrada solo dentro de una ventana de tiempo
   configurada por el backend (`409 EDIT_WINDOW_EXPIRED` pasada esa ventana).

## Reglas de negocio a respetar en la UI

- No ofrecer el botón de eliminar si, con el reloj local, ya pasó la ventana de edición conocida —
  pero igual manejar el 409 con gracia si el reloj del dispositivo está desfasado.
- Si la categoría del servicio exige bitácora (`requiresProgressLog`), mostrar el mensaje
  `PROGRESS_LOG_REQUIRED` de forma clara si el profesional intenta completar sin ninguna entrada —
  no un error genérico.
- Comparte el guard de consentimiento de `specs/data-and-media-consent.md` para las fotos subidas.

## Fuera de alcance de esta spec

Comentarios del cliente sobre una entrada puntual, geolocalización por entrada, reusar una foto de
bitácora como evidencia de portafolio (ver `specs/professional-documents.md`).
