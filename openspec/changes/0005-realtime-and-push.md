# Fase 0005 — Tiempo real y notificaciones push

## Antes de empezar

Leer: `specs/realtime-location.md`, `specs/notifications-push.md`,
`TekoApp-Backend/.claude/documentation/notifications-push-architecture.md`.

## Bloqueo a confirmar ANTES de arrancar esta fase

La parte de push **depende de trabajo pendiente en el backend** (ver documento de arquitectura de
push) — confirmar en ese momento que el backend ya implementó el modelo de suscripción FCM, los
endpoints de registro de token, y que `NotificationsProcessor` efectivamente envía FCM (no solo
loguea). Si no está listo, hacer primero la parte de tiempo real (geolocalización) de esta fase,
que no depende del backend más allá de lo que ya existe hoy.

## Tareas — Tiempo real

- [ ] Investigar y resolver la hipótesis de mismatch de secreto JWT en el `LocationsGateway` (ver
      `specs/realtime-location.md`) contra el backend real ANTES de asumir que el handshake de
      socket va a funcionar sin fricción.
- [ ] Emisión de ubicación como profesional online (frecuencia a definir, balance batería/
      precisión) con el disclosure de permisos correcto en Android e iOS.
- [ ] Mapa de profesionales cercanos (modo cliente) con actualización en vivo.
- [ ] Tracking en vivo del profesional asignado durante un servicio ACCEPTED/IN_PROGRESS.
- [ ] Decidir en `decisions.md` qué SDK de mapas usar (Google Maps es el candidato dado que el
      backend ya lo usa, confirmar antes de comprometerse).

## Tareas — Push (solo si el backend ya está listo, ver bloqueo arriba)

- [ ] Registro de token FCM al loguear, eliminación al cerrar sesión.
- [ ] Manejo de notificación en los 3 estados de la app (foreground/background/cerrada).
- [ ] Deep linking desde notificación a la pantalla relevante usando el `referenceId` del `data`
      de la notificación.
- [ ] Permiso de notificaciones pedido con contexto (no apenas se abre la app).

## Checkpoint de salida

- [ ] Dos dispositivos/emuladores reales: uno como profesional online, otro como cliente viendo
      el mapa — la posición del profesional se actualiza en vivo en el mapa del cliente.
- [ ] Si push está en alcance de esta fase: una notificación enviada desde el backend real llega
      al dispositivo con la app en los 3 estados (foreground/background/cerrada), y tocarla navega
      a la pantalla correcta.
- [ ] Apagar el modo online del profesional detiene la emisión de ubicación (verificable en los
      logs del backend, no solo "la app dejó de mandar" a ojo).
