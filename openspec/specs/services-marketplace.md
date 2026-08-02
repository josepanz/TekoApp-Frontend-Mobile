# Spec: Marketplace de servicios (núcleo del producto)

## Modelo de dominio (ya implementado en el backend, replicar el contrato tal cual)

- **Category**: catálogo jerárquico (categoría → subcategorías), con `icon`/`color` para UI.
  `GET /categories/all` (uso admin, sin filtrar) vs `GET /categories` (filtrado activo+visible,
  uso público) — usar el segundo para las pantallas de cliente/profesional.
- **ServiceType**: tipo de servicio dentro de una categoría (instalación, reparación,
  mantenimiento, emergencia).
- **Professionals**: perfil profesional de un usuario — `categoryId`, `hourlyRate`/`fixedRate`,
  `skills[]`, `yearsOfExperience`, `status` (PENDING/APPROVED/REJECTED/SUSPENDED), `isAvailable`,
  `isOnline`, `averageRating`/`totalRatings`/`totalServices` (calculados, no editables desde la
  app).
- **Services**: la solicitud de servicio en sí — creada por un cliente, eventualmente asignada a
  un profesional (`professionalId` nullable hasta que se acepta), con `status`
  (PENDING/ACCEPTED/IN_PROGRESS/COMPLETED/CANCELLED), ubicación (`latitude`/`longitude`/`address`),
  y montos (`hourlyRate`/`fixedPrice`/`totalAmount`/`finalAmount`).
- **ServiceRequests**: propuestas de profesionales sobre un `Service` en estado PENDING (varios
  profesionales pueden competir por el mismo servicio antes de que el cliente elija uno) —
  `proposedPrice`/`proposedHours`/`message`, `status` (PENDING/ACCEPTED/REJECTED/EXPIRED).

## Flujos de UI esperados

### Modo cliente

1. Pedir un servicio: elegir categoría → tipo de servicio → describir + ubicación → confirmar.
   Crea un `Service` en PENDING.
2. Ver profesionales cercanos disponibles (antes o después de pedir, según UX que se defina) — usa
   los endpoints de geolocalización (ver `specs/realtime-location.md`).
3. Ver mis servicios (listado propio, todos los estados) con detalle de cada uno.
4. Si hay varias `ServiceRequests` compitiendo por mi servicio PENDING: elegir un profesional
   (acepta esa `ServiceRequest`, rechaza las demás implícitamente).
5. Calificar al profesional al completarse el servicio (ver `specs/payments.md` para el flujo
   completo pago+calificación).

### Modo profesional

1. Ver solicitudes de servicio disponibles en mi categoría/zona (servicios PENDING sin profesional
   asignado, o donde ya envié una `ServiceRequest`).
2. Proponer precio/horas para un servicio (crea una `ServiceRequest`).
3. Ver mis servicios asignados (aceptados/en progreso/completados).
4. Marcar en progreso / completado (cambia `status` del `Service`).
5. Toggle de disponibilidad/online (`isAvailable`/`isOnline` de mi perfil profesional) — ver
   `specs/realtime-location.md` para el envío de posición mientras está online.

## Reglas de negocio a respetar en la UI (ya implementadas server-side, la UI debe reflejarlas)

- Un servicio solo puede pasar de PENDING → ACCEPTED → IN_PROGRESS → COMPLETED en ese orden (o a
  CANCELLED desde PENDING/ACCEPTED) — no ofrecer transiciones de estado que el backend va a
  rechazar.
- Cambios de estado concurrentes pueden devolver 409 (ver `project.md`) — la UI debe manejar esto
  mostrando "esto cambió, actualizá" en vez de un error genérico.
- Calificación: un usuario solo puede calificar una vez por servicio+profesional+tipo de
  calificación (`CLIENT_TO_PROFESSIONAL`/`PROFESSIONAL_TO_CLIENT`) — el backend lo rechaza con
  conflicto si se intenta de nuevo, la UI debería directamente ocultar la opción de calificar de
  nuevo una vez calificado.

## Fuera de alcance de esta spec

Pagos (ver `specs/payments.md`), notificaciones de nueva solicitud/aceptación (ver
`specs/notifications-push.md`), tracking de ubicación en vivo durante un servicio en progreso (ver
`specs/realtime-location.md`).
