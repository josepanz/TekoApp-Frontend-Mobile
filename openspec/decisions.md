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

## Almacenamiento seguro de tokens: decidido (verificado contra el backend real, 2026-08-07)

**`accessToken`**: `flutter_secure_storage` (usa Keychain en iOS, EncryptedSharedPreferences/
Keystore en Android). Viaja en el body JSON de `POST /auth/login`
(`AuthApiController.login` lo devuelve explícito) y se adjunta manualmente como
`Authorization: Bearer <token>` — confirmado en `JwtStrategy` (backend) que acepta
`ExtractJwt.fromAuthHeaderAsBearerToken()`, funciona igual sin servidor intermedio.

**`refreshToken`: NUNCA viaja en el body JSON — descubrimiento real, no un candidato a evaluar.**
Leyendo `AuthApiController`/`AuthCookieService` del backend: el login lo setea **solo** como cookie
`httpOnly`+`sameSite=strict` (`res.cookie('refreshToken', ...)`), y `POST /auth/refresh-token` lo
lee de `req.cookies?.refreshToken`, nunca de un header ni de un campo del body. `sameSite=strict`
es una restricción de navegador — no afecta a un cliente HTTP nativo como `dio`, que sí puede
mandar y recibir cookies con un cookie jar propio.

**Decisión**: `cookie_jar` (`PersistCookieJar`) + `dio_cookie_manager` como interceptor de `dio`
para capturar el `Set-Cookie` del login y reenviarlo en el refresh — no hay forma de evitarlo dado
el contrato real. Para que la persistencia entre reinicios de la app sea "almacenamiento seguro" de
verdad (`PersistCookieJar` con su `Storage` default escribe JSON plano en disco), envolver con un
adapter de la interfaz `Storage` de `cookie_jar` que lea/escriba a través de
`flutter_secure_storage` en vez de archivo plano.

**Estado**: decidido, pendiente de implementar en la Fase 0002 (`core/auth/cookie_jar_provider.dart`).

## Cifrado RSA del login: `pointycastle`, padding OAEP-SHA256 (verificado contra el backend real, 2026-08-07)

**Motivo del candidato**: no hay equivalente directo en Dart del helper Node de `TekoApp-Web`;
`pointycastle` es la librería RSA activa y mantenida del ecosistema Flutter.

**Padding exacto — no es un detalle a "verificar más adelante", ya está confirmado leyendo
`CryptoHelper.decrypt`/`AuthPasswordService` del backend**: `RSA_PKCS1_OAEP_PADDING` con
`oaepHash: 'sha256'` — en `pointycastle` esto es `OAEPEncoding.withSHA256(RSAEngine())`, que usa
ese mismo digest tanto para el hash principal como para MGF1 (`mgf1Hash = hash` en `init()`,
código de `pointycastle/asymmetric/oaep.dart`) — igual que Node cuando se pasa un solo `oaepHash`.
El payload cifrado es el JSON completo `{"password":"...","nonce":"..."}`
(`AuthPasswordService.decryptLoginPayload`), no solo el password.

**Nota sobre el doc-comment de `pointycastle`**: su propio código fuente advierte que implementa
"RSAES-OAEP v2.0 (RFC 2437)", no v2.1+/RFC 3447 (que es lo que usa OpenSSL/Node), y las marca como
incompatibles. **Verificado empíricamente que no es un problema real** para este caso: se generó un
par de claves con Node (`crypto.generateKeyPairSync`), se cifró `{password, nonce}` con
`RsaEncryptor` (pointycastle) y se descifró con `crypto.privateDecrypt` + `RSA_PKCS1_OAEP_PADDING`/
`oaepHash: 'sha256'` (la llamada exacta de `CryptoHelper.decrypt`) — el JSON recuperado fue
byte-a-byte idéntico al original. La "incompatibilidad" de la que habla pointycastle es solo un
detalle de longitud en la serialización interna (un byte `0x00` inicial que v2.1+ antepone antes de
la primitiva RSA) que no cambia el entero cifrado para claves RSA reales — no aplica en la
práctica. Test de round-trip (con claves de prueba propias, mismo mecanismo) en
`test/core/auth/rsa_encryptor_test.dart`.

**Estado**: decidido e implementado — `core/auth/rsa_encryptor.dart`, con compatibilidad cruzada
con Node ya verificada (no solo asumida). Pendiente únicamente: José corriendo la app contra el
backend local para confirmar el flujo end-to-end con la clave pública real (vía
`GET /auth/public-key`).

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

**Estado (actualizado 2026-08-07)**: `lib/design_system/tokens.generated.dart` ya existe con
constantes `Color(0x...)` para toda la paleta (`TekoPrimitives`) y el mapeo semántico claro/oscuro
(`TekoThemeColors.light`/`.dark`), pero **generado a mano con un script Node de un solo uso**
(convierte cada `oklch(L C H)` de `tokens.json` a sRGB con el algoritmo de CSS Color Module Level
4 — Dart no tiene soporte nativo para OKLCH), no por un formato nuevo en
`TekoApp-Web/src/design-system/tokens/build.mjs`. Se verificó que reproduce exacto los anclajes de
marca ya documentados (`primary.500`→`#28A745`, `neutral.900`→`#0D1B2A`, `neutral.50`→`#F5F7FA`).

**Pendiente real**: agregar un formato `dart/teko-theme` a `build.mjs` (mismo patrón que el
formato `css/teko-theme` que ya existe ahí) para que este archivo se regenere solo cuando
`tokens.json` cambie — hoy, un cambio de paleta en `TekoApp-Web` NO se refleja acá hasta que
alguien vuelva a correr el script a mano. Tocaría `TekoApp-Web` (otro repo), no se hizo en esta
sesión para no expandir el alcance sin que José lo pida explícitamente.

## Testing: `flutter_test` + `mocktail`

**Motivo**: decidido al ejecutar la Fase 0001 (bootstrap) — `mocktail` no depende de code
generation (a diferencia de `mockito`, que necesita `build_runner`), lo que mantiene el ciclo de
test más simple mientras el proyecto es chico. Se usa ya en
`test/core/api_client/envelope_interceptor_test.dart` para mockear `ResponseInterceptorHandler`.

**Estado**: decidido e implementado (Fase 0001).

## CI/CD: GitHub Actions, 3 ambientes, sin firma de release todavía

**Motivo**: mismo proveedor que `TekoApp-Backend`/`TekoApp-Web`, consistencia del ecosistema.
`.github/workflows/ci.yml` corre `flutter analyze` + `flutter test` en cada push/PR a
`develop`/`qa`/`master` (los 3 ambientes, igual que los otros 2 repos).

**Mapeo de ambientes** (mismo criterio que el resto del ecosistema):

| Rama | Ambiente | Play Console (futuro) | App Store / TestFlight (futuro) |
|---|---|---|---|
| `develop` | dev | track "internal" | build interno (sin distribuir) |
| `qa` | qa | track "closed testing" | grupo de beta en TestFlight |
| `master` | prod | "production" | App Store público |

`.github/workflows/build.yml` (disparo manual, con input `environment: dev\|qa\|prod`) valida que
compile un APK Android (`--debug`, sin keystore de release) y un build de iOS para simulador
(`--no-codesign`), pasando el `API_BASE_URL` correspondiente al ambiente elegido vía
`--dart-define` — solo validación de compilación, nunca publica nada.

**`.github/workflows/release.yml`** (agregado después de Fase 0001, ver ARCHITECTURE.md sección
CI/CD para el detalle completo de secrets) — versiona con semantic-release en cada push a
`develop`/`qa`/`master`, compila APK+AAB (Android, las 3 ramas) e IPA (iOS, solo qa/master) y los
publica como assets del GitHub Release. Si existen los secrets de firma/tienda correspondientes,
también sube el build a Google Play / App Store Connect — **el pipeline ya está completo e
implementado**, funciona hoy mismo sin ningún secret cargado (assets sin firma de release real) y
se activa solo, ambiente por ambiente, a medida que se cargan los secrets.

**Lo que falta para que los releases lleguen firmados a las stores** (bloqueado por cuentas/infra
externas que hay que crear una sola vez, no por decisión técnica ni por trabajo de pipeline
pendiente — ver ARCHITECTURE.md para el paso a paso exacto de cada secret):

1. Cuenta de Google Play Console + keystore de firma → secrets `ANDROID_KEYSTORE_BASE64` /
   `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD`.
2. Cuenta de Apple Developer Program + certificado de distribución + provisioning profile →
   secrets `IOS_CERTIFICATE_P12_BASE64` / `IOS_CERTIFICATE_PASSWORD` /
   `IOS_PROVISIONING_PROFILE_BASE64` / `IOS_TEAM_ID`.
3. Cuenta de servicio de Play Console API + API Key de App Store Connect → secrets
   `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` / `APP_STORE_CONNECT_API_KEY_ID` /
   `APP_STORE_CONNECT_API_ISSUER_ID` / `APP_STORE_CONNECT_API_KEY_BASE64`.
4. Proyecto Firebase real (uno por ambiente o uno solo con distintos flavors) →
   `google-services.json`/`GoogleService-Info.plist` por ambiente, nunca committeados (ver
   `.gitignore`) — bloquea FCM, no bloquea el release de instaladores en sí.
5. Backend real desplegado en `qa`/`prod` (hoy solo existe local) para que
   `API_BASE_URL_QA`/`API_BASE_URL_PROD` apunten a algo real.

**Estado**: decidido e implementado — build de validación multi-ambiente (Fase 0001) y pipeline de
release completo (`release.yml`); publicación real firmada a las stores pendiente únicamente de
cargar las credenciales de los puntos 1-3 arriba (sin trabajo de código adicional).

## i18n: `flutter_localizations` + `intl` (formalizado 2026-08-08, ya en uso desde la Fase 0002)

**Motivo**: `specs/i18n.md` lo dejaba como "a evaluar contra `easy_localization` antes de
implementar" — en la práctica, la Fase 0002 ya lo adoptó de hecho (`l10n.yaml`, `generate: true`
en `pubspec.yaml`, `lib/l10n/es.arb`/`en.arb`) porque es el camino estándar del SDK de Flutter
(sin dependencia externa, generación de código en build time) y ya viene funcionando sin fricción
en 2 fases. No hay motivo real para reabrir la comparación.

**Estado**: decidido, formalizando acá una decisión ya tomada en la práctica — no hay cambio de
código en esta entrada.

## Offline-first vs. online-only: **online-only** (confirmado con José, 2026-08-08)

**Motivo**: el dominio de esta fase (servicios que cambian de estado en tiempo casi real,
competencia entre profesionales por un mismo servicio) hace que cualquier dato cacheado localmente
quede obsoleto rápido — una lista "offline" mostraría estados que ya no son ciertos, más riesgoso
que útil. Online-only también evita agregar una capa de persistencia/sincronización (Hive/sqflite)
a una fase que ya es grande.

**Cómo aplica en código**: ningún listado (`categorías`, `mis servicios`, `disponibles`,
`propuestas`) se persiste entre reinicios de la app — Riverpod cachea en memoria solo dentro de la
sesión activa (mismo comportamiento que ya tiene `sessionProvider`), cada pantalla refetchea al
entrar o al reintentar tras un error. Revisitar si en producción se detecta que la app se usa en
zonas de conectividad inestable.

**Estado**: decidido, aplica desde la Fase 0003 en adelante salvo que se reabra explícitamente.

## Aceptación de servicio: modelo `ServiceRequests` competidoras (divergencia deliberada de `TekoApp-Web`)

**Motivo**: el backend soporta dos mecanismos para que un profesional se quede con un `Service`
PENDING: (1) `POST /services/:id/accept` — atajo "primero que acepta, gana", sin negociación, es
lo único que usa `TekoApp-Web` hoy; (2) `POST /services/:id/requests` (proponerse) +
`PUT /services/:id/requests/:requestId` (el cliente elige una) — con auto-rechazo transaccional
server-side de las demás propuestas competidoras al aceptar una. `specs/services-marketplace.md` y
las tareas de `changes/0003-services-marketplace-core.md` piden explícitamente el flujo (2) — mobile
implementa ese, no el atajo del web.

**Por qué no es un bug ni una inconsistencia a "corregir"**: son dos mecanismos reales que el
backend ya sostiene en paralelo (verificado en `services.controller.ts`/`services-db.service.ts`)
— web usó el más simple porque le alcanzaba para su alcance actual, mobile necesita el otro porque
su spec pide competencia entre profesionales. Si en el futuro se quiere unificar el comportamiento
entre web y mobile, es una decisión de producto aparte, no un fix.

**Estado**: decidido, implementar en los Pasos 2/7/8 de la Fase 0003.

## Paginación de listados de servicios: solo primera página por ahora

**Motivo**: `GET /services` pagina (`page`/`pageSize`), pero ni la spec ni el checkpoint de la
Fase 0003 piden scroll infinito — agregar esa capa ahora es scope extra no pedido (KISS). Se
consume la respuesta paginada tal cual (`{data, pagination}`) pero la UI solo pide/muestra la
primera página.

**Estado**: decidido para el alcance de la Fase 0003. Revisitar (scroll infinito o paginación
explícita en UI) si en producción las listas superan una página cómodamente navegable.

## Geolocalización para "pedir servicio": `geolocator`, sin mapa interactivo todavía

**Motivo**: la Fase 0003 solo necesita capturar `latitude`/`longitude`/`address` al crear un
`Service` — no tracking en vivo ni "profesionales cercanos" (eso es `specs/realtime-location.md`,
fuera de alcance de esta fase). `geolocator` es el paquete estándar del ecosistema Flutter para
permisos + posición actual del dispositivo; alcanza con un botón "usar mi ubicación actual" +
campo de dirección de texto libre, sin selector de pin en mapa (ningún paquete de mapas está
decidido todavía, y el checkpoint de esta fase no lo exige).

**Estado**: decidido para el alcance de la Fase 0003. Selector de pin en mapa queda pendiente para
cuando se aborde `realtime-location`.

## Fase 0004 — pagos y calificaciones: hallazgos verificados contra el backend real

Antes de escribir código se releyó `specs/payments.md` y el código real de `TekoApp-Backend`
(controllers/DTOs/schema), no solo el spec — se encontraron varias divergencias entre lo
documentado y el contrato real, ya corregidas del lado backend (PR #24/#25 de `TekoApp-Backend`,
2026-08-08) antes de construir mobile sobre él.

- **Monto del pago = `Service.finalAmount`**: ya existe en `ServiceDetailResponseDTO` (opcional,
  numérico) — se agrega a `Service` (mobile) y se manda tal cual en `CreatePaymentDto.amount`,
  nunca editable por el usuario en la pantalla de confirmación.
- **`professionalId` en `POST /payments` viaja como UUID** (`referenceId` del profesional) — el
  backend tenía un bug real (`Number(dto.professionalId)` sobre un campo `@IsUUID()`, daba `NaN`)
  que ya se corrigió (`PaymentDbService.findProfessionalByReferenceId`). Mobile manda
  `service.professional!.referenceId`, no el `id` Int.
- **`POST /promotions/validate` (preview, sin efecto) vs `POST /promotions/apply` (efecto real,
  incrementa el uso)**: mobile llama `validate` cuando el usuario ingresa el código (para mostrar
  el descuento) y `apply` recién al confirmar el pago — nunca `apply` como preview.
- **`CreatePaymentDto` no tiene campo de promoción** — el flujo real es aplicar la promoción
  primero (`apply` con `serviceAmount = service.finalAmount`) para obtener el `finalAmount` con
  descuento, y mandar ESE valor como `amount` en `POST /payments`.
- **Monto disponible para reembolso** = `payment.totalAmount - (payment.refundDetails?.refundedAmount
  ?? 0)` — no hay un campo `availableForRefund` explícito en el DTO, se calcula client-side con
  estos dos campos ya expuestos (confirmado leyendo `payment-db.service.ts`).
- **No existe un endpoint de "historial de transacciones" (`PaymentTransaction[]`) expuesto por la
  API** — el alcance de "detalle de transacciones" de esta fase se reduce a los campos propios de
  cada `Payment` (estado, fechas, `refundDetails`), no se fabrica una lista que el backend no da.
- **Mensajes de error textuales del backend en casos puntuales** (`CANNOT_DELETE_ONLY_METHOD`,
  errores de reembolso): el shape real de error es `{success:false, error:{code, message, error,
  timestamp, path}}` (`HttpExceptionFilter`), y `EnvelopeInterceptor` (mobile) solo desenvuelve
  respuestas exitosas — el mensaje crudo llega intacto en
  `dioException.response?.data['error']['message']`. Se agrega una variante de `Failure` que carga
  ese mensaje textual en vez de solo clasificar por status code (nuevo patrón vs. Fase 0003).
- **Calificación**: `professionalId`/`clientId` van como UUID (`referenceId`) — confirmado en
  `RatingsService`, sin el bug de pagos. **Corrección tras leer el código real** (la primera
  hipótesis, basada en el nombre del campo, era incorrecta): pese a que
  `CreateRatingRequestDTO`/`CreateProfessionalToClientRatingRequestDTO` y el endpoint
  `GET /ratings/service/:serviceRequestId` nombran el campo/parámetro `serviceRequestId`,
  `ratings.service.ts#resolveServiceId` SIEMPRE lo resuelve vía `findServiceByReferenceId` — es
  decir, en los tres casos el valor esperado es el `referenceId` (UUID) del propio `Service`, NO
  el de un `ServiceRequest` (propuesta). No hace falta resolver ninguna propuesta `ACCEPTED`: se
  manda `service.id` directamente (ya disponible en `serviceDetailProvider`). Queda documentado
  como una inconsistencia de nombres real pero inofensiva del backend (mismo dato, nombre
  confuso) — no se corrigió ahí porque renombrar el campo del body sería un cambio de contrato
  público sin beneficio funcional, dado que esta fase recién empieza a consumirlo. Para ocultar
  "calificar" si ya se calificó (pedido explícito de la tarea, no solo manejo de error 400) se usa
  `GET /ratings/service/:id` (mandando el `service.id`) para chequear antes de mostrar el botón.
- **`Service.client`** (mobile) — se agregó al modelo, mapeado desde la clave JSON `users` de
  `ServiceDetailResponseDTO` (así, en singular pese al nombre plural — otro detalle de naming real
  del backend, documentado en el propio modelo). Necesario para que el profesional pueda calificar
  al cliente (`CreateProfessionalToClientRatingRequestDTO.clientId`).
- **Gestión de métodos de pago sin integración real de tokenización**: no hay SDK de proveedor de
  pagos en esta fase — el formulario captura `type`/`provider`/`name`/`details` (campos de texto
  simples, ej. últimos 4 dígitos ingresados a mano) y los manda tal cual a `POST /payments/methods`
  — alcanza para "gestión de métodos de pago propios", sin flujo de alta real con proveedor, mismo
  criterio de scope ya aplicado a geolocalización/paginación en la Fase 0003.

**Estado**: decidido para el alcance de la Fase 0004. La estandarización de PK (`id`+`referenceId`)
en los 6 modelos del backend (Services/ServiceRequests/Payments/PaymentMethodEntity/
PaymentTransaction/Rating) ya estaba hecha a nivel de schema antes de esta fase — el contrato
público (`id`=UUID en la respuesta) no cambió, así que no afecta nada de lo ya construido en
Mobile.

## Qué NO se decidió todavía (pendiente explícito, no un olvido)

- Implementación del flujo de login real (nonce + RSA-OAEP + almacenamiento de tokens) — el
  mecanismo ya está decidido y verificado contra el backend real (ver las secciones específicas
  más arriba), el código en sí es tarea de la Fase 0002.
- Firma de release y publicación en Google Play / App Store — bloqueado por no tener las cuentas
  todavía, no por falta de decisión técnica (ver "CI/CD" arriba).
- Selector de pin en mapa para ubicación (ver "Geolocalización" arriba) — paquete de mapas sin
  decidir, pendiente de `specs/realtime-location.md`.

## Fase 0005 — SDK de mapas: `flutter_map` + OpenStreetMap (corregido, no Google Maps)

Decisión revertida explícitamente por José: no usar `google_maps_flutter` — Google exige tarjeta
de crédito cargada para emitir cualquier API key de mapa (ver
`TekoApp-Backend/.claude/documentation/entorno-dev-demo.md`), aunque el backend ya use Google Maps
para geocoding server-side. Mobile usa **`flutter_map`** (paquete open-source, MIT, sin key ni
cuenta) con tiles de **OpenStreetMap** — cero fricción para levantar el mapa en un dispositivo real
hoy mismo. Contras aceptados: sin geocoding/autocompletado de direcciones propio (no lo necesita
esta fase, que solo pinta pines de profesionales/ubicación en vivo, no busca direcciones), estilo
visual más genérico que Google Maps. Revisar si en algún momento el negocio pide autocompletado de
direcciones en mobile — ahí sí evaluar un proveedor de geocoding aparte (no necesariamente Google).

## Fase 0005 — Emisión de ubicación: alcance foreground-only por ahora

El profesional emite su ubicación en vivo (`Geolocator.getPositionStream`, `distanceFilter: 25m`
para no mandar cada frame de GPS) solo mientras la app está en foreground — se corta al minimizar
o cerrar la app (el socket se desconecta con el widget/provider, no hay `WorkManager`/background
isolate todavía). Evita deliberadamente el disclosure de permiso de ubicación en background
(`ACCESS_BACKGROUND_LOCATION` en Android, "Always" en iOS) — regulado por las políticas de ambas
tiendas y no necesario para la primera versión funcional. Reabrir si el negocio pide tracking real
con la app minimizada.

Falta explícitamente: la parte "cliente" (mapa de profesionales cercanos vía `flutter_map`/
`ProfessionalLocationUpdate` ya modelado, y tracking del profesional asignado durante un servicio
ACCEPTED/IN_PROGRESS) — solo se construyó el lado emisor (profesional) en este paso.

## Fase 0005 — hipótesis de JWT del socket de `/locations`: confirmada y corregida

No era un riesgo de mismatch, era un bug real y total: `LocationsModule` registraba su propio
`JwtModule` con `secret: process.env.JWT_SECRET` — esa env var no existe en este proyecto (el JWT
real es RS256 vía `JWT_PUBLIC_KEY`), así que el secreto siempre era `undefined` y **todo** handshake
del socket con un token real fallaba. Corregido en `TekoApp-Backend` (PR #29) para verificar con
`JWT_PUBLIC_KEY`/RS256 igual que el resto de la app. También se encontró y eliminó
`WebSocketConfig`/`WsAuthGuard` — un gateway duplicado en el mismo namespace `/locations`, mismo
bug, nunca registrado en ningún módulo (código muerto, no afectaba runtime).

**Hallazgo nuevo, no resuelto todavía**: `LocationsGateway.handleConnection` usa
`payload.professionalId || payload.sub` para la sala `professional:${id}`, pero el access token
real nunca lleva `professionalId` (solo `sub` = `referenceId` del User) — así que hoy la sala se
arma con el UUID del User, no del Professional. Resolver el contrato de sala/ids al diseñar el
emisor de ubicación de mobile (próximo paso), no asumido todavía.

## Backlog — features grandes pedidas 2026-08-08, pendientes de spec dedicada (NO implementadas)

José pidió estas 5 ampliaciones en la misma sesión en la que se cerró la Fase 0004. Ninguna se
implementa todavía — cada una necesita su propio `openspec/changes/000N-*.md` (0006 en adelante —
Fase 0005 ya está reservada para realtime/push) antes de escribir código, porque tocan los 3 repos
a la vez y 2 de ellas (propinas, marco legal/tributario) tienen implicancias financieras/legales
que no se deciden por default.

### 1. `id`/`referenceId` — estandarizar exposición en TODOS los dominios (decisión final)

El contrato estándar para TODA entidad de negocio (los 6 dominios que hoy solo exponen el UUID
bajo `id`, y también los que ya separan ambos como `Category`/`Professionals`) es exponer
**ambos** campos, siempre, en detalle Y en listado:
- `id` (Int secuencial): solo para ordenamiento — **nunca** se usa como clave de consulta/lookup.
- `referenceId` (UUID): la única clave válida para consultar, rutear o hacer deep-link — como ya
  documenta `flutter-architecture.md` en este repo.

**Ejecutar ahora, en dev, no después de publicar** — el mismo cambio de contrato es barato hoy (sin
usuarios reales, sin apps ya instaladas desde una tienda) y caro después (forzaría versionar la
API y actualizar clientes instalados). Alcance: backend agrega `id` a las respuestas de los 6
dominios que hoy solo devuelven `referenceId` bajo la clave `id`; Mobile/Web se actualizan en el
mismo ciclo de release para usar `id` únicamente en columnas de orden/sort de listados, nunca para
navegar o pedir detalle. Ver `TekoApp-Backend/.claude/rules/database-conventions.md` para el
estado de schema (ya migrado, solo falta el contrato de respuesta).

### 2. Propinas (tips) al pagar un servicio

- Entidad separada (tabla propia, FK a `Payment`) — nunca fusionada al monto del pago.
- Visible en el detalle Y en el listado de pagos con un ícono/tooltip que indique "incluye
  propina" (no un monto mezclado que haya que inferir).
- **No entra en el cálculo de comisión de la plataforma** — la comisión se calcula solo sobre el
  monto del `Payment` (servicio); la propina es 100% del profesional.
- 3 modos de cálculo: porcentaje configurable, monto fijo, o monto libre decidido por el cliente
  sin restricción de porcentaje. Opcional u obligatoria según parámetro configurable/legislación
  del país (ver ítem 4 — algunas jurisdicciones regulan si una propina puede ser obligatoria).

### 3. Calificaciones — anonimato entre usuarios, transparencia total para admins, KPIs para todos

- El anonimato es **entre cliente y profesional únicamente** — ninguno de los dos puede ver ni
  matchear/correlacionar quién lo calificó cruzando contra sus pedidos/servicios recientes.
- **Los administradores de TekoApp en la web ven todo sin restricción** si lo desean: identidad,
  orden, filtros, quién dijo qué — explícitamente para prevenir/responder actos legales y mejorar
  el rastreo de casos (disputas, moderación, abuso). Sus KPIs (por servicio, mes, día, etc.)
  también quedan completamente atribuibles internamente.
- **Clientes y profesionales también ven sus propios KPIs/dashboard** (servicios y calificaciones
  por día, semana, mes, etc.) — pensado como enganche visual, no solo para admins — pero sin
  quién/cuándo se dijo cada comentario puntual. El listado detallado de sus propias calificaciones
  (con comentarios) no necesita ser una pantalla prominente — puede vivir en un lugar secundario
  de la navegación, no en el home ni destacado.

### 4. Marco legal + tributario multi-país (Paraguay, Mercosur, EE.UU., internacional) — todo parametrizable

Alcance inicial: Paraguay, todos los países del Mercosur, Estados Unidos, e internacional (base
tipo GDPR como paraguas), extensible a medida que el proyecto entre a nuevos países. Objetivo:
blindar legalmente la recolección de datos — documentar, por cada dato recabado (incluyendo
fotos), **qué es, por qué se guarda y con qué objetivo** (principio de minimización/limitación de
propósito); y una cláusula de deslinde de responsabilidad explícita sobre contenido generado por
el usuario (lo que el usuario diga, suba o publique, incluyendo fotos). Incluye el **protocolo de
IVA/impuestos** según la legislación de cada país mencionado (tasas, aplicabilidad, requisitos de
facturación) y contrato cliente↔profesional con firma digital al aceptar un servicio.

**Todo debe ser parametrizable** — no hardcodear tasas de IVA, textos legales por país, ni reglas
de propina por jurisdicción: tabla de configuración por país/región, editable sin deploy de
código. Este principio de "parametrizable por defecto" aplica en general a toda esta ampliación,
no solo a impuestos.

**Límite explícito de esta sesión**: no soy asesor legal ni impositivo. Puedo modelar el flujo
técnico (captura de consentimiento, versionado de ToS/política de privacidad con auditoría de
aceptación por timestamp+hash, flujo de firma digital, tabla de configuración de tasas de IVA por
país/región), pero el **contenido legal y las tasas impositivas reales deben venir de asesoría
legal/impositiva real por país, no redactarse por inferencia de un LLM** — marcar esto como
prerrequisito antes de que esta feature sea usable en producción, no como un detalle a completar
después.

### 5. Branding centralizado y versionado (Web + Mobile)

Logo, banner, tipografía, colorimetría y **hasta el nombre de la app** deben poder cambiarse desde
un punto centralizado — vía parámetro/valor/variable, sin tocar código disperso — para poder
rebrandear fácilmente (ya existe `tokens.json` en `TekoApp-Web/src/design-system/tokens/` como
fuente de verdad de marca consumida por ambos fronts, ver `design-system.md` de este repo; esta
ampliación es formalizar/completar ese mecanismo para que cubra también logo/banner/nombre de app,
no solo color/tipografía). Requiere un `.md` versionado documentando cómo cambiar cada valor y el
historial de versiones de marca — vive junto al `tokens.json` o en `openspec/specs/` según
corresponda cuando se escriba la spec dedicada.

## Fase 0005 — Mapa de profesionales cercanos (modo cliente)

`GET /locations/nearby` devolvía la fila cruda de Postgres tal cual sale de `$queryRaw`
(snake_case, NUMERIC como string) — nunca pasa por el `$extends` de Prisma que normaliza el resto
de la API. Corregido en backend (PR aparte, `NearbyProfessionalResponseDTO` + mapper) antes de
construir el cliente contra ese contrato.

`NearbyProfessionalsController` hace el fetch inicial centrado en la posición actual del
dispositivo y luego escucha `locationUpdated` del mismo socket de `/locations` que usa la emisión
del profesional — un cliente solo escucha, nunca emite. Como el socket es una instancia única para
toda la app (compartida con `OnlineStatusController`), `SocketIoLocationsSocketService.connect()`
ahora es un no-op si ya hay una conexión viva — evita que abrir el mapa como cliente corte la
emisión de la misma cuenta operando como profesional online al mismo tiempo.

Pendiente explícito, no implementado en esta pasada: tracking en vivo del profesional asignado
durante un servicio ACCEPTED/IN_PROGRESS (usa `/tracking`, un módulo Mongo aparte con otra forma de
datos — GeoJSON, sin `referenceId` ni perfil — ver `TekoApp-Backend/src/api/tracking/`) y push
notifications (FCM, bloqueado en un proyecto Firebase real que debe crear José).

## Fase 0005 — Tracking en vivo del profesional asignado (ACCEPTED/IN_PROGRESS)

Reutiliza el mismo socket de `/locations` (namespace único, ver `SocketIoLocationsSocketService`)
en vez del módulo `/tracking` (Mongo, GeoJSON, sin `referenceId`/perfil) — más simple y consistente
con el mapa de cercanos, sin tocar backend: `GET /locations/professional/:id` (ya existía) da la
última posición conocida, y el mismo evento `locationUpdated` la actualiza en vivo, filtrando por
`professionalId` en el cliente. Si el profesional nunca activó "online", no hay ubicación (404
esperado) y la sección de tracking simplemente no se muestra — no es un error de cara al usuario.

`assignedProfessionalLocationProvider` es `StreamProvider.autoDispose.family` — a diferencia de
`OnlineStatusController`/`NearbyProfessionalsController` (viven toda la sesión), este SÍ se
destruye al salir de la pantalla del servicio. Encontrado con tests: riverpod 2.x no tiene
`ref.mounted` (recién en 3.x) — hubo que trackear el dispose a mano (`var disposed = false;
ref.onDispose(() => disposed = true)`) para no leer providers de un container ya destruido si la
pantalla se cierra mientras el fetch inicial estaba en vuelo.

Con esto se completa el checklist de código de la Fase 0005 — queda pendiente solo push (FCM,
bloqueado en que José cree un proyecto Firebase real) y el checkpoint de salida con dispositivos
reales.
