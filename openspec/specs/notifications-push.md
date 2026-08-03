# Spec: Notificaciones (in-app + push)

> Ver `TekoApp-Backend/.claude/documentation/notifications-push-architecture.md` para la decisión
> completa y el estado real verificado del backend — esta spec asume que ese documento ya se leyó.

## Estado de dependencia — actualizado 2026-08-02: backend YA listo

El backend implementó el modelo de suscripción FCM, `POST`/`DELETE /notifications/fcm-tokens`, y
`NotificationsProcessor` envía FCM de verdad (`admin.messaging().send()`, ya no solo loguea) — ver
`TekoApp-Backend/.claude/documentation/notifications-push-architecture.md` para el detalle
completo (endpoints, modelo de datos, manejo de tokens muertos). **Verificar igual contra el
backend real corriendo localmente antes de implementar** — no asumir que el endpoint documentado
sigue vigente sin probarlo.

## Comportamiento esperado

### Notificaciones in-app (ya funcionan hoy, no bloqueado)

- `GET /notifications` (paginado) — historial de notificaciones del usuario actual.
- `GET /notifications/unread/count` — badge de no leídas.
- `PUT /notifications/:id/read` / `PUT /notifications/read-all` — marcar como leídas.
- Tipos de notificación ya modelados server-side: `service_request`, `service_accepted`,
  `service_rejected`, `service_completed`, `payment_received`, `rating_received`, `promotion`,
  `system` — cada uno con su propio ícono/tratamiento visual esperado en la UI (no todas las
  notificaciones se ven igual).

### Push (Firebase Cloud Messaging) — backend listo, falta el cliente Flutter

1. Al loguear (o al abrir la app con sesión activa), pedir el token FCM
   (`FirebaseMessaging.instance.getToken()`) y registrarlo contra
   `POST /notifications/fcm-tokens` (`{ token, deviceType: 'ANDROID' | 'IOS' }` — ya implementado
   y probado del lado backend).
2. Manejar los 3 estados de la app al recibir una notificación (`firebase_messaging` los expone
   con callbacks distintos — revisar la doc oficial del paquete al implementar, no asumir un solo
   handler):
   - App en foreground: mostrar una notificación in-app propia (banner), no depender del sistema
     operativo para mostrarla.
   - App en background: el sistema operativo la muestra; al tocarla, navegar al detalle relevante
     (ej. el servicio/pago que originó la notificación).
   - App cerrada: mismo comportamiento que background, manejar el "cold start desde notificación".
3. Al cerrar sesión: eliminar el token FCM registrado
   (`DELETE /notifications/fcm-tokens/:referenceId`) — evita seguir recibiendo push de una cuenta
   de la que el usuario ya salió en ese dispositivo.
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
