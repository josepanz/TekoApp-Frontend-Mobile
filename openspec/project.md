# Contexto heredado — leer antes de cualquier otra cosa

Todo lo que sigue viene de construir y endurecer `TekoApp-Backend` y `TekoApp-Web` en sesiones
previas. Es la base de conocimiento que esta app mobile hereda gratis, sin tener que redescubrirla.

## El dominio, en una página

TekoApp conecta **usuarios** (piden servicios) con **profesionales** (los ofrecen). Una misma
cuenta puede operar en ambos roles — `TekoApp-Web` ya lo resuelve con un selector de modo
(cliente/profesional/admin) sobre la misma sesión; esta app debería replicar esa misma decisión,
no separar en dos apps.

Dominios de negocio ya implementados en el backend (todos con CRUD + reglas de negocio reales, no
solo esqueletos): usuarios/profesionales, categorías de servicio, solicitudes de servicio,
calificaciones bidireccionales, pagos (con métodos de pago, transacciones, reembolsos),
promociones, roles/permisos, ubicación en tiempo real (Socket.io + Mongo/2dsphere), notificaciones
(hoy in-app, push documentado como decisión — ver `specs/notifications-push.md`).

## Auth — el contrato exacto que el backend espera

El backend usa JWT propio (access + refresh) con esta forma:

- **Login**: `POST /auth/login` con Basic Auth de **cliente** (no de usuario — un
  `clientId:clientSecret` compartido por toda la app, análogo a un API key de aplicación) +
  `{ email, encryptedPassword }` donde `encryptedPassword` es el password real cifrado con
  **RSA-OAEP** usando la clave pública del backend (`BACKEND_JWT_PUBLIC_KEY`), más un **nonce**
  anti-replay de un solo uso (`POST /auth/nonce` primero, el nonce viaja *dentro* del payload
  cifrado junto al password: `encryptPassword(JSON.stringify({ password, nonce }))`).
- **Por qué esto y no un login "normal"**: decisión ya tomada y probada en el backend — nunca
  cuestionar este contrato desde mobile, implementarlo tal cual. El nonce evita que un request de
  login capturado (ej. por un proxy MITM comprometido) se pueda reenviar tal cual.
- **Cifrado RSA en Dart**: no hay equivalente directo del helper de Node usado en
  `TekoApp-Web` (`src/core/auth/rsa-encrypt.ts`) — investigar un paquete Dart que soporte
  RSA-OAEP con la misma clave pública (`pointycastle` es candidato, verificar compatibilidad con
  el padding OAEP exacto que usa el backend antes de asumir que "cualquier RSA sirve").
- **Tokens resultantes**: `accessToken` (vida corta, ~15 min) + `refreshToken` (vida larga, ~12h)
  — en `TekoApp-Web` viajan como cookies httpOnly porque hay un servidor Next.js de por medio; acá
  **no hay ese servidor intermedio**, así que hay que decidir dónde guardarlos de forma segura en
  el dispositivo (ver `decisions.md` — pendiente de decidir explícitamente: `flutter_secure_storage`
  es el candidato obvio, pero no está confirmado todavía).
- **Refresh**: `POST /auth/refresh-token` con el refresh token — implementar un interceptor de
  `dio` que reintente automáticamente un 401 refrescando el token una vez, igual que cualquier
  cliente HTTP con auth por token debería hacer.
- **El JWT es "delgado" a propósito**: `sub`/email/status/nombre únicamente — **nunca** trae
  `permissions`/`roles`/`id` embebidos. Para saber permisos/roles/datos completos del usuario
  actual, se llama `GET /auth/scope` (devuelve `{ user: {...}, roles: [...], permissions: [...] }`
  con datos frescos de la DB, incluyendo `avatarUrl` ya resuelto a una URL presignada válida). Este
  es el mismo endpoint que ya usa `TekoApp-Web` para toda la sesión — replicar el patrón: nunca
  decodificar el JWT para leer permisos, siempre preguntarle a `/auth/scope`.
- **Autoedición de perfil**: `PUT /auth/me` (nombre/apellido/teléfono/avatar) — no requiere
  permisos especiales, solo estar autenticado. Separado a propósito de la edición admin
  (`PUT /users/:id`, que sí requiere permiso `USER.UPDATE`/`ADMIN.ALL`).

## El contrato público de la API — nunca exponer IDs internos

Todo modelo de negocio en el backend tiene dos identificadores:

- `id`: entero secuencial, **interno**, nunca sale de Postgres/las respuestas de API pensadas para
  mostrar en URLs.
- `referenceId`: UUID público, es el que viaja en las rutas (`GET /users/reference/:referenceId`)
  y el que se debe usar para cualquier navegación/deep link en la app.

Excepción histórica ya documentada en el backend (`Services`, `ServiceRequests`,
`PaymentMethodEntity`, `Payments`, `PaymentTransaction`, `Rating` usan UUID como PK primaria
directamente, sin `id` secuencial separado) — no afecta a mobile, solo importa si en algún momento
se toca el modelo de datos del backend.

## Avatares — nunca guardar la URL, siempre volver a pedirla

`GET /auth/scope` y las respuestas de usuario devuelven `avatarUrl` como una **URL presignada de
S3 que expira en 900 segundos** (bug real encontrado y corregido en el backend: la primera versión
guardaba la URL cruda, que dejaba de servir la imagen ~15 minutos después de subida). La regla
para mobile: **nunca cachear `avatarUrl` más allá de la sesión actual** — si se necesita mostrar
un avatar después de que la app estuvo en background un rato largo, volver a pedir el dato (nuevo
`GET /auth/scope` o el endpoint de detalle correspondiente), nunca asumir que la URL vieja sigue
sirviendo.

Subida de avatar: `POST /uploads/avatar` (multipart) devuelve `{ key, url, ... }` — se persiste el
**`key`** (permanente) vía `PUT /auth/me { avatarKey }`, nunca la `url` (presignada, expira).

## Errores encontrados en el camino que mobile debería evitar de entrada

Estos son bugs **reales**, encontrados y corregidos durante la construcción de backend/web — no
son hipotéticos, ya costaron tiempo de debugging una vez:

1. **Zona horaria**: nunca usar `America/Asuncion` como identificador de timezone — Paraguay
   abolió el horario de verano (Ley 7127) pero esa zona IANA sigue cargando reglas de DST según el
   tzdata del dispositivo, causando desfasajes de ±1h. Usar un offset fijo (`Etc/GMT+3`, o el
   equivalente que use la librería de fecha/hora de Dart) para cualquier cálculo de "hora de pared
   de Paraguay".
2. **Condiciones de carrera en operaciones concurrentes de estado** (aceptar/cancelar un servicio,
   reembolsar un pago): el backend ya protege esto con `updateMany` + chequeo de `count` en vez de
   `findUnique` + `update` — desde mobile esto significa: **siempre estar preparado para un 409
   Conflict** en cualquier acción que cambie el estado de un servicio/pago, y mostrarlo como "esto
   cambió mientras tanto, refrescá" — nunca asumir que la acción del usuario siempre gana.
3. **Listados vacíos nunca son un error**: `GET` de cualquier listado devuelve `200` con
   `data: []` cuando no hay resultados — nunca tratar una lista vacía como un estado de error en
   la UI de mobile.
4. **El backend envuelve toda respuesta exitosa** en `{ success, data, message, timestamp, path }`
   — el cliente HTTP de mobile necesita desenvolver esto de forma centralizada (un interceptor de
   `dio`), igual que `TekoApp-Web` lo hace en `core/api-client/client.ts#apiFetch`. Nunca asumir
   que el body de la respuesta es el DTO "pelado".

## Qué NO replicar de `TekoApp-Web` (patrones específicos de tener-un-servidor-intermedio)

`TekoApp-Web` resuelve varias cosas con un servidor Next.js de por medio (BFF) que **mobile no
tiene**: cifrado RSA del lado servidor, inyección de Basic Auth sin exponerlo al cliente, cookies
httpOnly. Mobile va a necesitar resolver el equivalente de forma nativa (guardar el secreto de
cliente en el binario/config de la app — no es lo mismo que un secreto server-side, hay que asumir
que es extraíble con suficiente esfuerzo de reversing; documentar esto como limitación conocida en
`decisions.md` cuando se decida cómo manejarlo, no ignorarlo).

## Diseño — una sola fuente de verdad, no una reinterpretación

`tokens.json` (`TekoApp-Web/src/design-system/tokens/tokens.json`, formato W3C Design Tokens) ya
está preparado explícitamente para un output Dart adicional desde el mismo `build.mjs` (Style
Dictionary) cuando arranque este repo — **no rediseñar la paleta/tipografía a mano en Flutter**,
generarla desde ese archivo. Ver `specs/design-system.md`.

## Idioma

`TekoApp-Web` ya tiene traducción completa es/en (next-intl, negociación por cookie +
`Accept-Language`, español por default). El backend traduce sus propios mensajes de error/validación
vía `nestjs-i18n` (header `x-lang` o `Accept-Language`). Mobile debería enviar el header/preferencia
correspondiente y tener su propio catálogo es/en — ver `specs/i18n.md`.
