# Decisiones de arquitectura — mobile

Formato: decisión → motivo → estado. Agregar acá cualquier decisión nueva no cubierta todavía,
antes de implementarla — nunca dejar una decisión de arquitectura solo implícita en el código.

## Framework: Flutter 3

**Motivo**: ya estaba decidido antes de esta sesión de documentación (ver README histórico del
backend, que ya listaba Flutter como stack de mobile en su tabla de ecosistema). Un solo codebase
para iOS + Android, y comparte el modelo mental de "widget tree declarativo" con React (más fácil
la transferencia de patrones aprendidos en `TekoApp-Web`).

**Estado**: decidido, no reabierto en esta sesión.

## Estado: Riverpod

**Motivo**: es el manejo de estado recomendado hoy para Flutter en proyectos de tamaño mediano/
grande con múltiples fuentes de datos async (network, cache) — más testeable que `Provider` a
secas (no depende del árbol de widgets para el ciclo de vida), y tiene un equivalente conceptual
directo a TanStack Query de `TekoApp-Web` (`useQuery`/`useMutation`) vía `FutureProvider`/
`AsyncNotifier`, lo que facilita portar el patrón mental "hook por operación de servidor" ya
validado en el frontend web.

**Estado**: decidido en esta sesión, no implementado — validar con un spike chico (una sola
pantalla, ej. login) antes de comprometerse para todo el proyecto.

## Ruteo: go_router

**Motivo**: es el paquete de ruteo declarativo oficial recomendado por el equipo de Flutter,
soporta deep linking (necesario si en algún momento se comparten links a un servicio/profesional
específico) y guards de ruta (equivalente a `proxy.ts` de `TekoApp-Web` para proteger rutas sin
sesión).

**Estado**: decidido en esta sesión, no implementado.

## Cliente HTTP: dio

**Motivo**: soporta interceptors (necesario para el patrón "adjuntar Bearer token + reintentar en
401 refrescando" descrito en `project.md`), maneja multipart de forma nativa (subida de avatar/
documentos), y es el cliente HTTP de facto en el ecosistema Flutter para necesidades más allá de
`http` básico.

**Estado**: decidido en esta sesión, no implementado.

## Almacenamiento seguro de tokens: pendiente de confirmar

**Candidato**: `flutter_secure_storage` (usa Keychain en iOS, EncryptedSharedPreferences/Keystore
en Android).

**Motivo del candidato**: es el estándar para guardar tokens de auth en Flutter sin depender de
`shared_preferences` plano (que no está cifrado).

**Estado**: **NO decidido todavía** — confirmar explícitamente en la Fase 2 (`changes/0002-...`)
antes de implementar el flujo de login, no asumir este paquete sin evaluarlo primero contra
alternativas activas en ese momento (el ecosistema Flutter cambia rápido; verificar que el paquete
siga mantenido cuando se llegue a esa fase).

## Notificaciones push: Firebase Cloud Messaging

**Motivo**: ver el razonamiento completo en
`TekoApp-Backend/.claude/documentation/notifications-push-architecture.md` — decisión tomada para
los 3 repos: Web Push (VAPID) en `TekoApp-Web`, FCM acá.

**Estado (actualizado 2026-08-02): backend YA implementado, deja de estar bloqueado por
infraestructura.** El backend conectó `firebase-admin` de verdad (`modules/push-provider/`,
`FcmProviderService`) y expone:

- `POST /notifications/fcm-tokens` — registrar/actualizar el token FCM del dispositivo.
- `DELETE /notifications/fcm-tokens/:referenceId` — dar de baja un token.
- `NotificationsProcessor` envía de verdad vía `admin.messaging().send()` cuando una notificación
  declara el canal `fcm`, y desactiva el token si Firebase reporta
  `messaging/registration-token-not-registered` (no reintenta indefinidamente).

Lo único que sigue bloqueado es la falta de un **proyecto Firebase real** para esta app (no hay
`google-services.json`/`GoogleService-Info.plist` todavía) y, obviamente, de código Flutter que
consuma esos endpoints — no es un bloqueo de arquitectura backend, es trabajo de esta fase. Ver
`changes/0005-realtime-and-push.md`, que ya refleja este desbloqueo.

## Diseño: tokens compartidos, no reinterpretados

**Motivo**: ver `project.md` — `tokens.json` ya está pensado para generar un output Dart adicional
sin duplicar la definición de marca. Evita que mobile termine con una paleta ligeramente distinta
a la web por una reinterpretación manual de los mismos colores.

**Estado**: decidido, mecanismo de generación (qué formato de Style Dictionary produce Dart válido
— probablemente un archivo `.dart` con constantes `Color(0x...)`) sin definir todavía — es tarea
de `changes/0002-auth-and-design-system.md`.

## Qué NO se decidió todavía (pendiente explícito, no un olvido)

- Testing: framework de testing de Flutter (`flutter_test` + `mocktail`/`mockito`) — sin decidir
  cuál usar para mocks, evaluar en la Fase 1.
- CI/CD: pipeline de build/firma para iOS y Android — fuera de alcance de esta sesión de
  documentación, decidir cuando el proyecto tenga código real para buildear.
- Offline-first vs. online-only: no se decidió si la app necesita funcionar sin conexión (ej. ver
  servicios ya cargados) — el dominio (servicios en tiempo real, ubicación en vivo) sugiere que
  online-only es razonable para el MVP, pero es una decisión de producto, no técnica, que falta
  confirmar con el negocio antes de la Fase 3.
