# Spec: Preferencias de notificación y bandeja in-app (Mobile)

Plan de fase: `openspec/changes/platform-hardening-2026-09/WORKPLAN.md`, tarea I-04. Solo spec —
sin implementación (ver instrucción explícita de la tarea).

## Objetivo

`lib/features/notifications/` hoy es únicamente el gateway de token FCM
(`registerFcmToken`/`removeFcmToken`, ver `notifications_repository.dart`) — recibe pushes vía
`PushNotificationGateway` y navega a la pantalla correspondiente (`push_notification_payload.dart`),
pero no hay ninguna pantalla donde ver el HISTORIAL de notificaciones (una vez descartado el
banner del push, se pierde) ni forma de elegir qué tipos de notificación recibir.

## Hallazgo de la verificación previa que cambia el alcance real de esta spec

A diferencia de I-01/I-03, **la bandeja in-app NO está bloqueada por trabajo de backend nuevo** —
`TekoApp-Backend` ya tiene el sistema completo construido y funcionando (`src/api/notifications/`,
`src/modules/notifications-db/`, Mongo): `GET /notifications` (historial paginado),
`GET /notifications/unread`, `GET /notifications/unread/count`, `PUT /notifications/:id/read`,
`PUT /notifications/read-all`, `DELETE /notifications/:id`, y un stream SSE
(`GET /notifications/stream`, "solo cubre app abierta ahora mismo, complementario a FCM" según su
propio `@ApiOperation`). Nada de esto se migró a `/v1` (ver M-07) — no está en la lista de
controllers versionados verificada en esa tarea.

**Pero (verificado leyendo el código, no asumido)**: `NotificationsService.create()` — el único
punto de entrada que persiste una notificación y encola su envío — solo lo puede llamar el propio
usuario autenticado sobre sí mismo (`POST /notifications`, sin campo `userId` en el DTO, el
controller pasa `req.user.id` a mano). **Ningún dominio de negocio** (`payments`, `services`,
`ratings`, ver grep sin resultados sobre `NotificationsService` en esos módulos) llama a este
servicio todavía. Esto significa que, aunque el inbox esté "listo" del lado backend, hoy **no se
generaría contenido real** — un pago recibido o un servicio aceptado no crean una fila en
`notifications`. Este es un gap del lado `TekoApp-Backend` (conectar los eventos de dominio reales
a `NotificationsService.create()`), **fuera de alcance de esta spec de Mobile** — se documenta acá
para que quien implemente no asuma que el historial va a tener contenido real sin ese trabajo
también hecho, y para que se levante como hallazgo en el WORKPLAN de `TekoApp-Backend`.

## Alcance de esta spec (Mobile)

**Incluye**: pantalla de bandeja (`/notificaciones`), un ícono de campana con badge de no-leídas
en la navegación principal, y una pantalla de preferencias por tipo de notificación.

**No incluye (fuera de esta fase)**: el trabajo de backend para conectar eventos de dominio reales
al inbox (ver hallazgo arriba — es de `TekoApp-Backend`), preferencias reales (ver Decisión de
alcance del backend abajo — hoy no hay dónde persistirlas), consumo del stream SSE (ver Decisión).

## Bandeja in-app — diseño

- `lib/features/notifications/data/notifications_repository.dart` (ya existe) suma
  `fetchAll({limit, offset})`, `fetchUnreadCount()`, `markAsRead(id)`, `markAllAsRead()`,
  `delete(id)` — mismo archivo, no uno nuevo, ya es el dueño del dominio `notifications`.
- `NotificationItem` (modelo nuevo, `models/notification_item.dart`): mapea
  `NotificationResponseDTO`. **Ojo**: `id`/`userId` acá son ObjectId de Mongo (string), no el
  patrón `id`(int)/`referenceId`(UUID) del resto del backend — es así en el propio contrato del
  backend, no una inconsistencia a corregir del lado Mobile. Solo usar `id` (string) para
  leer/marcar/borrar, nunca intentar un `int.parse` sobre él.
- Ícono de campana en la barra superior de home (`home_screen.dart` o el shell de navegación
  principal, a confirmar el punto exacto al implementar) con un badge del conteo de
  `fetchUnreadCount()` — refrescar ese conteo cuando la app vuelve a foreground (mismo criterio
  que cualquier dato "que puede haber cambiado mientras la app estaba en background", no hace
  falta un stream para esto).
- `NotificationsInboxScreen` (`/notificaciones`): lista paginada (mismo patrón de paginación que
  `payment_history_screen.dart` si ya usa scroll infinito, revisar al implementar), swipe-to-delete
  o botón de borrar por ítem, botón "Marcar todas como leídas", tap en un ítem navega usando
  `PushNotificationPayload.route` — mismo mapeo `type`→ruta que ya existe para el push en vivo,
  reusar esa lógica en vez de duplicarla (puede requerir extraer `route` a una función libre que
  tome `type`+`referenceId` en vez de un `RemoteMessage`, para que ambos modelos la compartan).

## Decisión: no consumir el stream SSE en esta fase

`GET /notifications/stream` da tiempo real mientras la app está abierta, pero Mobile ya tiene FCM
para eso (push en background/foreground) — agregar un segundo canal de tiempo real (SSE) para el
mismo propósito que ya cubre FCM es complejidad sin beneficio claro hoy. Si en el futuro se navega
sin recargar entre pantallas y se quiere que el badge de no-leídas se actualice al instante sin
esperar un pull-to-refresh o un vuelta-a-foreground, reconsiderar — no ahora.

## Decisión de alcance del backend: preferencias por tipo NO tienen dónde persistirse hoy

A diferencia del inbox, **esto sí está bloqueado por backend**: no existe ningún campo/tabla para
"qué tipos de notificación quiere recibir el usuario X" — ni en `Users` (Postgres/Prisma) ni en
Mongo. Se necesita (dependencia de esta spec, ver abajo) una de estas dos opciones — la decisión
final es de backend, no de esta spec:

1. Un campo JSON en `Users` (Postgres) — más simple, coherente con que el resto del perfil de
   usuario vive ahí.
2. Una colección `notification_preferences` en Mongo, junto al resto del módulo de notificaciones.

Sin uno de los dos, la pantalla de preferencias de Mobile no tiene contra qué leer/escribir.

## Preferencias — diseño de la UI (una vez exista el endpoint)

- Un switch por cada valor de `NotificationType` (9 hoy — ver
  `notification-type.enum.ts`: `service_request`, `service_accepted`, `service_rejected`,
  `service_completed`, `payment_received`, `rating_received`, `promotion`, `system`,
  `document_expired`) — agrupados por sección (servicios, pagos, calificaciones, marketing,
  sistema), no una lista plana de 9 switches sin jerarquía.
- **`system`/`document_expired` no deberían ser desactivables** (o al menos, requerir una
  confirmación explícita) — son notificaciones operativas (documento de verificación vencido,
  avisos de la plataforma), no marketing. Confirmar con José el criterio exacto al implementar, no
  asumir cuáles son "críticas" sin su decisión.
- Los cambios se guardan por switch (auto-save al togglear, no un botón "Guardar" al final) — mismo
  patrón que `online_status_controller_provider.dart` (una mutación = una acción del usuario, sin
  estado intermedio "sin guardar" que se pueda perder).

## Fuera de alcance de esta spec

Conectar eventos de dominio reales al inbox del backend (ver hallazgo arriba — es tarea de
`TekoApp-Backend`), consumo del stream SSE, un endpoint de preferencias ya diseñado en detalle (la
decisión Postgres-vs-Mongo es de backend), notificaciones agrupadas/resumidas ("3 servicios
nuevos" en vez de 3 filas), sonidos/vibración custom por tipo.

## Riesgos / límites explícitos

- **El inbox puede verse vacío en producción** hasta que el hallazgo de arriba se resuelva del
  lado backend — no es un bug de esta implementación, es una dependencia externa real. Vale la
  pena avisarle a José antes de invertir en la UI, para decidir el orden (¿conectar los eventos de
  dominio primero, o construir la UI igual y que quede vacía hasta que se conecten?).
- **Preferencias sin backend**: si se implementa la UI de bandeja antes que la de preferencias (son
  independientes), no hay problema — pero no construir la pantalla de preferencias hasta que
  backend confirme dónde persiste (Postgres vs. Mongo), para no adivinar un contrato y tener que
  rehacerlo.
