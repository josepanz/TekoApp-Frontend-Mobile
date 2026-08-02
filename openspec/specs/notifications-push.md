# Spec: Notificaciones (in-app + push)

> Ver `TekoApp-Backend/.claude/documentation/notifications-push-architecture.md` para la decisión
> completa y el estado real verificado del backend — esta spec asume que ese documento ya se leyó.

## Estado de dependencia (bloqueante)

**Esta capacidad depende de trabajo pendiente en el backend** (modelo de suscripción FCM,
endpoint de registro de token, wiring real de `NotificationsProcessor` a Firebase Admin SDK — hoy
solo loguea, no envía). No empezar a implementar recepción de push en mobile hasta confirmar que
el backend ya envía FCM de verdad — ver checkpoints en el documento del backend.

## Comportamiento esperado (una vez el backend esté listo)

### Notificaciones in-app (ya funcionan hoy, no bloqueado)

- `GET /notifications` (paginado) — historial de notificaciones del usuario actual.
- `GET /notifications/unread/count` — badge de no leídas.
- `PUT /notifications/:id/read` / `PUT /notifications/read-all` — marcar como leídas.
- Tipos de notificación ya modelados server-side: `service_request`, `service_accepted`,
  `service_rejected`, `service_completed`, `payment_received`, `rating_received`, `promotion`,
  `system` — cada uno con su propio ícono/tratamiento visual esperado en la UI (no todas las
  notificaciones se ven igual).

### Push (Firebase Cloud Messaging) — pendiente del backend

1. Al loguear (o al abrir la app con sesión activa), pedir el token FCM
   (`FirebaseMessaging.instance.getToken()`) y registrarlo contra el endpoint que el backend debe
   exponer (`POST /notifications/fcm-tokens`, todavía no existe — ver documento del backend).
2. Manejar los 3 estados de la app al recibir una notificación (`firebase_messaging` los expone
   con callbacks distintos — revisar la doc oficial del paquete al implementar, no asumir un solo
   handler):
   - App en foreground: mostrar una notificación in-app propia (banner), no depender del sistema
     operativo para mostrarla.
   - App en background: el sistema operativo la muestra; al tocarla, navegar al detalle relevante
     (ej. el servicio/pago que originó la notificación).
   - App cerrada: mismo comportamiento que background, manejar el "cold start desde notificación".
3. Al cerrar sesión: eliminar el token FCM registrado (`DELETE` del endpoint correspondiente,
   todavía no existe) — evita seguir recibiendo push de una cuenta de la que el usuario ya salió
   en ese dispositivo.
4. Permiso de notificaciones: pedirlo explícitamente en un momento con contexto (ej. después del
   primer servicio pedido/aceptado), no apenas se abre la app por primera vez sin explicar por qué
   — mejor tasa de aceptación real, aunque esto es una decisión de UX a confirmar con el negocio,
   no una regla técnica dura.

## Deep linking desde notificación

Cada tipo de notificación debería llevar a una pantalla específica al tocarla (ej.
`service_accepted` → detalle de ese servicio, `payment_received` → detalle de ese pago) — el campo
`data` de la notificación (ya modelado server-side como `Record<string, unknown>` libre) debería
llevar el `referenceId` de la entidad relevante para poder navegar directo, sin tener que buscar
por otro medio qué entidad originó la notificación.
