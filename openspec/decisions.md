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

1. **Keystore de firma Android** → secrets `ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD`
   / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD`. **Gratis, sin cuenta de Google, sin tarjeta** —
   es un archivo criptográfico generado localmente con `keytool` (parte del JDK), separado de
   cualquier cuenta de Google. Pasos (correr en la máquina de José, nunca commitear el `.jks` ni
   las contraseñas):
   ```
   keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 \
     -validity 10000 -alias tekoapp-release
   # pide 2 contraseñas (keystore + key, pueden ser iguales) y datos de identidad (nombre/org) —
   # esos datos no son secretos, van embebidos en el certificado, pero las contraseñas sí lo son.
   ```
   Codificar a base64 y cargar como secrets del repo (`gh secret set` o Settings → Secrets and
   variables → Actions):
   ```
   # PowerShell:
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("release-keystore.jks")) | Set-Content keystore-b64.txt -NoNewline
   gh secret set ANDROID_KEYSTORE_BASE64 < keystore-b64.txt
   gh secret set ANDROID_KEYSTORE_PASSWORD   # pega la contraseña del keystore cuando lo pida
   gh secret set ANDROID_KEY_ALIAS           # "tekoapp-release" (o el alias elegido arriba)
   gh secret set ANDROID_KEY_PASSWORD        # pega la contraseña de la key cuando lo pida
   ```
   Con esto solo (sin Play Console todavía) `release.yml` ya empieza a firmar los APK/AAB de
   verdad — resuelve el riesgo de firma documentado en `openspec/changes/0015-app-version-update.md`.
   **Guardar el `.jks` y las 2 contraseñas en un lugar seguro fuera del repo (gestor de
   contraseñas)** — si se pierde ese archivo, ninguna actualización futura puede firmarse con la
   misma identidad y todos los usuarios existentes tendrían que desinstalar y reinstalar.
2. Cuenta de Google Play Console (USD 25 único, si más adelante se quiere publicar en la store de
   verdad — no bloquea nada de lo de arriba).
3. Cuenta de Apple Developer Program + certificado de distribución + provisioning profile →
   secrets `IOS_CERTIFICATE_P12_BASE64` / `IOS_CERTIFICATE_PASSWORD` /
   `IOS_PROVISIONING_PROFILE_BASE64` / `IOS_TEAM_ID`.
4. Cuenta de servicio de Play Console API + API Key de App Store Connect → secrets
   `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` / `APP_STORE_CONNECT_API_KEY_ID` /
   `APP_STORE_CONNECT_API_ISSUER_ID` / `APP_STORE_CONNECT_API_KEY_BASE64`.
5. Proyecto Firebase real (uno por ambiente o uno solo con distintos flavors) →
   `google-services.json`/`GoogleService-Info.plist` por ambiente, nunca committeados (ver
   `.gitignore`) — bloquea FCM, no bloquea el release de instaladores en sí.
6. Backend real desplegado en `qa`/`prod` (hoy solo existe local) para que
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

## Fase 0006 — i18n, admin y pulido final

**Auditoría de strings sin traducir**: limpia — grep de `Text('...')`/`label:`/`hintText:`/
`tooltip:`/`message:` con literales hardcodeados en `lib/` no encontró nada. Confirma que la
disciplina "traducir sobre la marcha" (`.claude/rules/i18n.md`) se sostuvo en las Fases 0002-0005.

**Selector de idioma explícito**: agregado en "Mi perfil" (`_LanguageSelector`, junto al botón de
logout) — `Sistema` (sigue el idioma del dispositivo, default) / `Español` / `English`. Persistido
con `shared_preferences` (nueva dependencia — la única otra opción de storage local ya en el
proyecto, `flutter_secure_storage`, es para secretos, no para una preferencia de UI no sensible).
`LocaleController` (`core/locale/locale_provider.dart`) expone `Locale?`, `null` = sistema;
`app.dart` lo pasa a `MaterialApp.router(locale: ...)`.

**Decisión de producto — admin/backoffice en mobile**: NO. Queda exclusivo de `TekoApp-Web`
(portal de gestión ya establecido para el staff de TekoApp). Mobile es el cliente para
usuarios/profesionales — agregar un modo admin ahí duplicaría superficie sin un caso de uso real
(el staff administrativo no necesita gestionar la plataforma desde el celular hoy). Revisitar solo
si surge un pedido concreto de negocio.

**Accesibilidad**: pasada dirigida sobre controles solo-ícono (`IconButton`/`InkWell`/
`GestureDetector` en todo `lib/`) — un hallazgo real: las 5 estrellas de `rate_dialog.dart` no
tenían label accesible (`IconButton` sin `tooltip`, un lector de pantalla las anunciaba como
"botón" x5 sin indicar cuál calificación aplica cada una). Corregido con
`tooltip: l10n.ratingStarLabel(star)` (nueva key con plural ICU). El resto de los controles
solo-ícono ya tenían `Semantics(button:true, label:...)` (editar avatar) o no eran solo-ícono
(cards con texto). Contraste y targets táctiles: no se re-verificó a mano — se apoya en los mismos
tokens de `TekoApp-Web` ya auditados matemáticamente en su rebrand 2026-08-02 (`AppTheme.light/dark`
los consume sin reinterpretación, ver `.claude/rules/design-system.md`). Estados (`ServiceStatusBadge`
y otros `TekoBadge`) ya combinan texto+color, nunca solo color.

**Offline-first vs. online-only**: ya estaba decidido y confirmado con José (2026-08-08, ver
sección propia más arriba en este archivo) — sigue vigente, sin cambios en esta fase.

Con esto se cierra el checklist de tareas de la Fase 0006. El "checkpoint de salida" (cambiar
idioma en runtime y confirmar TODA la UI incluyendo errores del backend vía `x-lang`, accesibilidad
"corregida" no solo "revisada", recorrido de punta a punta de las Fases 2-5) queda para José con
la app corriendo en un dispositivo real — no verificable solo con `flutter test`/`flutter analyze`.

**Hallazgo adicional (mismo checklist, "checkpoint de salida")**: la app nunca mandaba el header
`x-lang` — el backend (`nestjs-i18n`, `LANGUAGE_HEADER = 'x-lang'`) nunca podía traducir sus
mensajes de error/validación al idioma activo de la UI, siempre caía a su default. Agregado
`LocaleHeaderInterceptor` (mismo patrón que `BearerAuthInterceptor`: lee el storage directo, sin
`ref` de Riverpod, para mantener `core/api_client` desacoplado del árbol de providers) — manda la
preferencia explícita guardada o, si no hay, el idioma del sistema si es uno soportado (si no,
español). Sin esto, cambiar el idioma en runtime dejaba media app traducida (UI sí, errores del
backend no) — exactamente el gap que el checkpoint de esta fase pedía confirmar.

## Backlog — features grandes pedidas 2026-08-22, pendientes de spec dedicada (NO implementadas)

Igual que el backlog de 2026-08-08: documentado para no perderlo, sin diseño técnico ni
implementación todavía — cada uno amerita su propio `openspec/changes/000N-*.md` cuando se
priorice.

### 6. Documentos y antecedentes del profesional (verificación de habilitación)

**Spec: ver `openspec/specs/professional-documents.md` + `openspec/changes/0007-professional-documents-and-background-checks.md`
(mobile), `TekoApp-Backend/openspec/specs/professional-documents.md` +
`TekoApp-Backend/openspec/changes/0001-professional-documents-and-background-checks.md` (backend),
`TekoApp-Frontend-Web/openspec/specs/professional-documents.md` +
`TekoApp-Frontend-Web/openspec/changes/0001-professional-documents-verification.md` (backoffice de
verificación).**

Dos categorías de documento a soportar, ambas **parametrizables** (qué se pide, si es obligatorio
u opcional, por país/categoría de servicio):

- **Antecedentes policiales y judiciales**: verificación activable/desactivable por
  parámetro (no todos los países/categorías la requieren igual) — quién la exige, con qué
  vigencia, y qué pasa si vence o falta.
- **Documentos de habilitación**: títulos, certificados, y evidencia de trabajos/experiencia
  previa (portafolio) — el profesional los carga, visibles para el cliente al elegir a quién
  contratar. Relacionado con el ítem 4 del backlog anterior (marco legal): estos documentos son
  datos personales/sensibles, entran en el mismo paraguas de consentimiento y minimización de
  datos ya documentado ahí.

### Rediseño visual del home de cliente (2026-08-25, decidido e implementado — Opción C)

**Spec: ver `openspec/changes/0013-client-home-redesign.md`.** Detectado al probar el primer APK
contra el backend cloud: `HomeScreen` era el scaffold crudo de la Fase 0001 (botones sueltos sin
jerarquía, texto de smoke test visible). José confirmó la Opción C (header con saludo + CTA
destacada de "pedir servicio" + grid secundario 2×2) — implementada, con test de widget nuevo
(`test/features/home/widgets/home_screen_test.dart`) y suite completa en verde (268/268). Pendiente
únicamente: verificación visual en dispositivo real (claro/oscuro), no cubierta por tests
automatizados.

### 7. Bitácora de trabajo — "paso a paso" documentado por el profesional

**Spec: ver `openspec/specs/work-progress-log.md` + `openspec/changes/0008-work-progress-log.md`
(mobile), `TekoApp-Backend/openspec/specs/work-progress-log.md` +
`TekoApp-Backend/openspec/changes/0002-work-progress-log.md` (backend). Sin spec dedicada de
`TekoApp-Frontend-Web` por ahora — decisión de alcance abierta para José, ver la nota en el spec de
backend (extender la vista de detalle de servicio ya existente en vez de una pantalla nueva).**

El profesional registra el avance de un servicio en curso (fotos, notas) para que el cliente vea
qué se hizo y cómo, no solo el estado final. Pensado como transparencia/trazabilidad del trabajo,
similar en espíritu al historial ordenado que ya ven los administradores de calificaciones (ítem 3
del backlog anterior) pero acá visible directamente para el cliente dueño del servicio.

### 8. Presupuestos multi-opción generados desde la app

**Spec: ver `openspec/specs/multi-option-quotes.md` + `openspec/changes/0009-multi-option-budgets.md`
(mobile), `TekoApp-Backend/openspec/specs/multi-option-quotes.md` +
`TekoApp-Backend/openspec/changes/0003-multi-option-quotes.md` (backend),
`TekoApp-Frontend-Web/openspec/specs/material-catalog.md` +
`TekoApp-Frontend-Web/openspec/changes/0002-budget-catalog-management.md` (catálogo de materiales,
backoffice).**

Antes de aceptar un servicio, el profesional arma uno o varios presupuestos alternativos
(materiales a elegir, nivel de calidad, mano de obra, distintos rangos de precio) para que el
cliente compare y elija — no un monto único fijo como hoy (`Service.finalAmount`, Fase 0004). Todo
parametrizable: qué campos tiene un presupuesto, cuántas opciones se permiten, catálogo de
materiales/calidades por categoría de servicio.

### 9. Contratos generados desde el presupuesto aceptado

**Spec: ver `openspec/specs/service-contracts.md` +
`openspec/changes/0010-contracts-from-accepted-budget.md` (mobile),
`TekoApp-Backend/openspec/specs/service-contracts.md` +
`TekoApp-Backend/openspec/changes/0004-service-contracts.md` (backend). Depende del ítem 8. Sin
spec dedicada de `TekoApp-Frontend-Web` por ahora (mismo criterio que el ítem 7) — el backend ya
expone `GET /admin/contracts` para que staff los vea desde la vista de servicio existente si hace
falta.**

Al aceptar un presupuesto (ítem 8), generar un contrato cliente↔profesional con firma digital —
extiende el contrato con firma digital ya mencionado en el ítem 4 del backlog de 2026-08-08, ahora
con el presupuesto elegido como contenido del contrato (materiales, precio, alcance del trabajo).

### 10. Disclosure de contenido generado por IA

**Spec: ver `openspec/specs/ai-content-disclosure.md` +
`openspec/changes/0011-ai-content-disclosure.md` (mobile),
`TekoApp-Backend/openspec/specs/ai-content-disclosure.md` +
`TekoApp-Backend/openspec/changes/0005-ai-content-disclosure.md` (backend),
`TekoApp-Frontend-Web/openspec/specs/ai-content-disclosure-admin.md` +
`TekoApp-Frontend-Web/openspec/changes/0003-ai-content-disclosure-admin.md` (auditoría,
backoffice).**

Si en algún punto se usa IA para generar/asistir texto, imágenes, o presupuestos dentro de la app
(descripciones sugeridas, fotos de referencia, etc.), debe quedar explícitamente marcado como tal
de cara al usuario — no presentarlo como contenido humano sin aclarar. Aplica tanto a lo que
genere la plataforma como, potencialmente, a contenido que un profesional/cliente suba y declare
como asistido por IA.

### 11. Protección de datos, imágenes y su uso

**Spec: ver `openspec/specs/data-and-media-consent.md` +
`openspec/changes/0012-data-and-image-consent.md` (mobile),
`TekoApp-Backend/openspec/specs/data-and-media-consent.md` +
`TekoApp-Backend/openspec/changes/0006-data-and-media-consent.md` (backend, spec más fundacional de
las 6 — ver su `openspec/README.md` para el orden real de implementación recomendado),
`TekoApp-Frontend-Web/openspec/specs/data-and-media-consent-admin.md` +
`TekoApp-Frontend-Web/openspec/changes/0004-consent-and-data-protection-admin.md` (config/auditoría,
backoffice). Comparte marco con el ítem 4 del backlog 2026-08-08 (marco legal/tributario) y con el
ítem 6 de este backlog (documentos/antecedentes).**

Consentimiento explícito y alcance de uso para todo dato/imagen subida a la app (fotos de avance
del ítem 7, documentos/antecedentes del ítem 6, fotos de perfil, evidencia de trabajos) — mismo
paraguas legal ya iniciado en el ítem 4 del backlog de 2026-08-08 (deslinde de responsabilidad
sobre contenido de usuario, minimización de datos), extendido explícitamente a cubrir estos casos
nuevos de carga de documentos/evidencia.

**Límite explícito, igual que en el backlog anterior**: el contenido legal real (qué exige cada
país, textos de consentimiento, validez de firma digital) requiere asesoría legal real por país —
esto solo documenta el flujo/producto a construir, no el contenido legal en sí.

## Fase 0012 — Consentimiento legal: implementado 2026-08-25

Roadmap punto 2 (después de la fundación backend `0006`, también cerrada 2026-08-25). Decisiones
tomadas durante la implementación, no explícitas en la spec original:

- **`ConsentGateway` + `ConsentRequiredBridge`**: mismo patrón ya usado por
  `PushNotificationGateway` (widget montado en `MaterialApp.router(builder: ...)`, usa
  `GoRouter.of(context)` desde su propio `context`) — necesario porque `ConsentRequiredInterceptor`
  (dio, `core/api_client`) no tiene `BuildContext` y `core/api_client` debe quedar desacoplado del
  árbol de widgets (ver comentario de `LocaleHeaderInterceptor`). El bridge es un
  `Completer`/`StreamController` simple: el interceptor pide y espera, el gateway navega y resuelve.
- **`errorCode` en el backend, no solo status 403** (amendment cruzado, ver
  `TekoApp-Backend/openspec/decisions.md`): sin un identificador máquina-legible, un interceptor
  GLOBAL de 403 (como pide la spec, "en CUALQUIER response") secuestraría cualquier otro 403 de la
  app (ej. permisos de un endpoint admin) — status code solo no alcanza acá, a diferencia de otros
  casos ya resueltos en la app donde el código es inequívoco por endpoint (ej. 409 en
  `POST /payments`).
- **`data/legal_consents_repository.dart`, no `legal_consents_api.dart`** — la spec usaba ese
  nombre literal, pero el resto del repo llama a esta capa "Repository" (`AuthRepository`,
  `PaymentsRepository`) — se siguió la convención real, no la redacción de la spec.
- **`url_launcher` en vez de un WebView embebido** para abrir el `contentUrl` real — la spec
  ofrecía ambas opciones explícitamente; se eligió la de menor huella de dependencias (no hay
  ningún paquete de WebView en el proyecto hoy).
- **Selector de `usageScope` diferido, no implementado en esta fase**: no existe todavía ningún
  formulario de subida de portafolio/documentos al que integrarlo (llega con `0007`/`0008`) — el
  modelo y el método de repositorio (`ContentConsentGrant.usageScope`,
  `LegalConsentsDbService.createContentGrant` en backend) ya están listos para cuando esos
  formularios existan.
- **`LegalConsentScreen` muestra TODOS los documentos pendientes de una**, no uno a la vez — el
  guard del backend (`RequiresActiveConsentGuard`) solo informa "falta consentimiento", nunca cuál
  `LegalDocumentType` puntual disparó el 403 (el `403 CONSENT_REQUIRED` es genérico), así que no
  hay forma de saber cuál mostrar primero — se resuelven todos juntos.

## Fase 0005 — Push notifications (FCM)

Cliente completo contra el backend ya listo (`POST/DELETE /notifications/fcm-tokens`,
`FcmProviderService` con payload `{notification:{title,body}, data:{referenceId,type}}`):

- **Registro/baja de token**: reacciona a `sessionProvider` (login → pedir permiso con contexto +
  registrar; logout → dar de baja) vía `PushNotificationGateway`, montado en
  `MaterialApp.router(builder: ...)`. El `referenceId` que devuelve el registro se persiste en
  `flutter_secure_storage` — el backend no lo resuelve por el token FCM crudo, hace falta guardarlo
  para poder darlo de baja en el logout.
- **Permiso con contexto**: diálogo propio (explica por qué, antes del picker nativo del SO),
  mostrado una sola vez (flag en `SharedPreferences`) al primer login — nunca al abrir la app.
- **3 estados manejados**: foreground → banner propio vía `ScaffoldMessenger` (el SO no muestra
  notificación sola cuando la app está abierta) — **decisión de alcance**: no se usa
  `flutter_local_notifications` (evita una dependencia nativa más con setup de canales/permisos
  propio) por ahora, un banner in-app alcanza; revisar si se pide paridad visual completa con el
  tray del SO. Background/cerrada → el SO ya muestra la notificación sola, solo se resuelve el
  deep link al tocarla (`onMessageOpenedApp`/`getInitialMessage`).
- **Deep linking por `type`**: `service_request`/`service_accepted`/`service_rejected`/
  `service_completed` → `/mis-servicios/:id`; `payment_received` → `/pagos/historial/:id`; el resto
  (`rating_received`, `promotion`, `system`) sin pantalla propia hoy, no navega. **Gap real
  encontrado**: no hay una pantalla de detalle de servicio del lado profesional (solo listado en
  `/profesional/mis-servicios`) ni una de calificación individual — si se agregan, extender el
  mapeo de `PushNotificationPayload.route`.
- **Hallazgo del backend**: ningún flujo de negocio real (aceptar servicio, recibir pago, etc.)
  llama todavía a `NotificationsService.create()` — el módulo de notificaciones es infraestructura
  genérica lista, pero nada dispara push hoy. Cablear esos triggers es trabajo de backend, fuera
  de esta fase (mobile).
- **Gradle/Firebase**: `google-services.json` de Android ya colocado y verificado (package
  `py.com.tekoapp.mobile` coincide). iOS sin `GoogleService-Info.plist` todavía — `Firebase.
  initializeApp()` está en un try/catch (no tumba el boot si falta config en alguna plataforma,
  mismo criterio que `FcmProviderService` en el backend). `flutter build apk --debug` verificado
  exitoso con la config real.

Con esto, el checklist completo de push de la Fase 0005 queda cerrado — el checkpoint de salida
(dos dispositivos reales, uno emitiendo, otro recibiendo) sigue pendiente de José.

## Rediseño visual — gradiente de marca (implementado 2026-08-25)

Roadmap punto 3 (rediseño visual, después de `0006`/`0012` de consentimiento). Fuera del backlog
de features 2026-08-22 — pedido de diseño separado, espejo del mismo trabajo en
`TekoApp-Frontend-Web` (ver su `openspec/decisions.md`, mismo día).

**`TekoGradientBackground`** (`lib/shared/widgets/`) — mismo gradiente que Web: diagonal
navy→teal→verde, `TekoPrimitives.neutral900` → `.accent700` → `.primary600` (shades accesibles,
no los 500 crudos — mismo criterio que `TekoThemeColors.light.primary` usa `primary600`). Aplicado
en:

- `LoginScreen` — fondo de página completa; el formulario (antes sin envoltorio propio) se
  envolvió en un `Container` con `Theme.of(context).cardColor`, ya que `TextFormField` asume fondo
  claro.
- `ProfessionalOnboardingScreen` — hero acotado arriba del formulario (no fondo completo — es un
  form largo y denso, un fondo oscuro detrás de tantos campos habría sido ilegible/recargado).
- `ProfessionalHomeScreen` (`_ProfessionalActiveBody`, el caso "con perfil activo") — hero acotado
  arriba del switch de disponibilidad, mismo criterio que el hero de `(client)/page.tsx` en Web
  (no fondo completo, para no competir con el switch/lista de servicios debajo). Los estados "sin
  perfil"/error/loading de `ProfessionalHomeScreen` quedan sin tocar — no tienen un momento "hero"
  natural.

**`HomeScreen` (cliente) — descartado deliberadamente**, a diferencia de los otros candidatos: ya
tiene su propio lenguaje visual fresco de la Fase 0013 (recién rediseñada hoy mismo, CTA `accent`
sólida + grid) — un fondo gradiente detrás hubiese competido con esa CTA en vez de complementarla.

**Estado**: implementado, `flutter analyze`/`flutter test` en verde (293/293, incluye 3 tests
nuevos del widget compartido).

## Fase 0011 — Disclosure de contenido generado por IA (implementado 2026-08-25)

`lib/features/ai_disclosures/` (`data`/`providers`/`models`) + `shared/widgets/ai_disclosure_badge.dart`.
Reusa `AiDisclosureEntityType` (`legal_consents/models/`, ya introducido en la Fase 0012) sin
duplicar — importado cross-feature deliberadamente, es un enum genuinamente compartido, no lógica
de dominio de `legal_consents`.

**Solo 2 formularios reales reciben el checkbox — verificado grepeando el código, no asumido.**
El spec pedía "revisar cuáles formularios existen realmente, no asumir la lista de hoy": hoy solo
`request_service_screen.dart` (→ `SERVICE_DESCRIPTION`) y `professional_onboarding_screen.dart`
(→ `PROFESSIONAL_DESCRIPTION`) tienen un campo de descripción real — coincide exactamente con
`APP_CONFIG.aiDisclosure.userDeclarableTypes` del backend (Fase 0005, mismo día).

**Patrón "declarar después de crear"**: ambos controllers (`RequestServiceController.submit()`,
`ProfessionalOnboardingController.submit()`) ahora capturan la entidad creada (antes se
descartaba) y, si `aiAssisted` es true, disparan `AiDisclosuresRepository.declare()` en un
`try/catch` que traga cualquier error — el disclosure es "siempre opcional y post-hoc" (spec), así
que nunca debe hacer fallar la creación del servicio/perfil ya exitosa. Nota de mapeo: `Service.id`
YA ES el UUID (`referenceId`) por la convención especial de esa tabla (ver
`.claude/rules/database-conventions.md` del backend); `ProfessionalProfile` sí usa `referenceId`
separado — cada controller usa el campo correcto según su modelo.

**Badge solo en `service_detail_screen.dart`.** Es la única pantalla real que renderiza el
contenido declarable a un viewer (la descripción del servicio). No existe hoy una pantalla de
"perfil profesional visible a terceros" en mobile (`professional_home_screen.dart` es el propio
dashboard del profesional, no muestra su bio) — no se inventó una pantalla nueva para justificar
el segundo badge, fuera de alcance de esta fase.

**`AiDisclosureFailure` distingue 403 de 400 por status code**, a diferencia de
`LegalConsentsFailure` (que colapsa ambos en un `Validation` genérico vía rango 400-500) — el
backend de esta fase ya devuelve un 403 real para "no sos dueño" (no un 409 con `errorCode` como en
consentimiento), así que alcanza con el status code sin mirar el envelope de error.

**Estado**: implementado, `flutter analyze`/`flutter test` en verde (301/301, incluye 5 tests
nuevos: 4 del repositorio + 2 del badge — más 1 ajuste a un test existente de
`request_service_screen_test.dart` que dejó de ver el botón de submit sin `ensureVisible` tras
agregar el checkbox, layout más alto).

## Fase 0015 — Chequeo y actualización de versión de la app: solo spec, NO implementada (2026-08-27)

Pedido nuevo de José (2026-08-27), fuera del roadmap de 9 puntos en curso — spec completa en
`openspec/specs/app-version-update.md`, plan de fase en
`openspec/changes/0015-app-version-update.md`. Ningún código escrito todavía.

**Decisiones tomadas al especificar** (detalle completo en la spec, resumen acá para no tener que
releerla entera en cada sesión futura):

- **Sin backend intermediario**: la app consulta `api.github.com` directo (repo público, sin
  token) — los releases de `.github/workflows/release.yml` ya son la fuente de verdad, duplicarla
  en `TekoApp-Backend` no aporta nada hoy.
- **Alcance Android únicamente**: iOS no permite sideload fuera de App Store/TestFlight/MDM, y
  `publish-ios-store` sigue bloqueado por falta de credenciales — no hay todavía un destino real
  al que redirigir en iOS. Se agrega como fase separada cuando eso exista.
- **Activo en los 3 ambientes por ahora** (incluido `prod`): hoy ninguno tiene distribución real
  vía Google Play (`has_play_publish` pendiente de secrets) — `prod` también se instala
  sideloadeando el APK del GitHub Release. Pendiente: revisar si desactivarlo en `prod` una vez
  que Play esté publicando de verdad, para no competir con su auto-update nativo.
- **Nunca cruzar ambientes**: cada build solo considera releases con el patrón de tag de su propio
  ambiente (`-develop.N`/`-qa.N`/sin sufijo para prod) — nunca "la versión más nueva de cualquier
  rama".
- **Comparación con `pub_semver`, no strings** — evita el bug real de `"develop.9" > "develop.10"`
  lexicográficamente.
- **2 riesgos dejados explícitamente sin resolver, a confirmar con José al implementar**: (1) los
  builds de `release.yml` hoy no tienen firma de release real (`ANDROID_KEYSTORE_BASE64` sin
  cargar) — instalar-sobre puede fallar con "app no instalada" en vez de actualizar limpiamente, y
  (2) qué paquete Flutter dispara el instalador Android (`open_filex`/`ota_update`/
  `install_plugin` son candidatos, ninguno fijado — verificar mantenimiento activo recién al
  implementar).

**Decisiones confirmadas con José (2026-08-28)**:
- **Alcance**: activo en los 3 ambientes (`dev`/`qa`/`prod`) desde el arranque — confirmado, no
  solo dev/qa. Revisar más adelante si desactivarlo en `prod` una vez que Google Play esté
  publicando de verdad.
- **Orden de trabajo**: José resolvió primero el prerrequisito de firma real — generó el keystore
  (`keytool`) y cargó `ANDROID_KEYSTORE_BASE64`/`ANDROID_KEYSTORE_PASSWORD`/`ANDROID_KEY_ALIAS`/
  `ANDROID_KEY_PASSWORD` como secrets del repo (2026-08-28, confirmado con `gh secret list`) ANTES
  de arrancar el código — `release.yml` ya estaba armado para consumirlos condicionalmente
  (`check-secrets` job), no hizo falta tocar el pipeline de firma en sí.

**Implementado 2026-08-28** — `lib/core/update/` completo.

**Elección del paquete instalador (pendiente explícito de la spec, resuelto ahora)**: `open_filex`
sobre `ota_update`/`install_plugin` — `ota_update` acopla descarga + instalación en un solo
paquete, duplicando la responsabilidad que ya cubre `dio` (la spec ya decidió descargar con
`onReceiveProgress`); `open_filex` solo dispara la apertura/instalación, componiendo limpio con
`ApkDownloader` separado. Verificado en pub.dev (2026-08-28): mantenido, "Compatibility with
Gradle 8+" declarado explícitamente.

**Corrección real encontrada al implementar, no asumida de la spec**: la spec pedía declarar un
`FileProvider` propio + `res/xml/file_paths.xml` en el manifest. Leyendo el `AndroidManifest.xml`
y el `filepaths.xml` que empaqueta `open_filex` (en el `.pub-cache`, antes de escribir el propio),
se confirmó que el plugin YA trae su propio `<provider>` (autoridad
`${applicationId}.fileProvider.com.crazecoder.openfile`) con un `cache-path` que cubre exactamente
el directorio de `getApplicationCacheDirectory()` usado por `ApkDownloader`. Declarar uno propio
además del que ya trae el plugin era una duplicación innecesaria — se descartó, el manifest final
solo agrega el permiso `REQUEST_INSTALL_PACKAGES` (eso sí, `open_filex` no lo declara).

**Segunda corrección real, encontrada recién al compilar un APK real (ni `flutter analyze` ni
`flutter pub get` la detectan)**: `permission_handler ^13.0.1` (la última al momento de agregar la
dependencia) subió su Android nativo a `compileSdk 37`, más nuevo que el `compileSdk 36` que trae
el Flutter estable de este proyecto — el build real falló con `Failed to find target with hash
string 'android-37'` (ni siquiera instalando la Platform 37 vía sdkmanager se resolvió, quedó con
un naming distinto en el SDK local). Fijado en `^12.0.0` (compila contra `compileSdk 35`,
compatible hacia adelante con 36) — confirmado con un build real (`flutter build apk --debug`)
después del downgrade, no solo con `pub get`/`analyze`, que no ejercitan la toolchain nativa de
Android.

**Tests**: 15 nuevos en `test/core/update/` — `environment_release_matcher_test.dart` (6: elige el
más reciente, nunca cruza ambientes, ignora sin asset APK, ignora drafts, sin match → null, prod
solo tags sin sufijo), `update_check_repository_test.dart` (5: hay actualización, comparación
semver real `develop.10` > `develop.9`, ya está actualizado → null, fail-open en error de red,
cachea el fetch dentro del TTL), `update_available_dialog_test.dart` (3: cancelar no descarga,
actualizar descarga+instala, error de descarga muestra mensaje claro sin cerrar el modal).

**Estado**: implementado y verificado — `flutter analyze` (0 issues), `flutter test` (todos
verdes, incluye los 15 nuevos), y un build real de APK debug (`flutter build apk --debug
--dart-define=APP_ENVIRONMENT=dev`) para confirmar que el manifest/dependencias nativas compilan
de verdad, no solo el análisis estático. Pendiente (no de código): probar la instalación real
sobre un dispositivo/emulador Android con un release firmado real publicado — checkpoint de
negocio a cargo de José, mismo criterio que otras fases.

## Fase 0008 — Bitácora de trabajo: implementado 2026-08-27 (mobile, tras cerrar el backend en la misma sesión)

`lib/features/service_progress/` completo (`data`/`models`/`providers`/`widgets`) — `ProgressTimeline`
embebido en `service_detail_screen.dart` (visible para ambos roles cuando `service.professional !=
null`), `AddProgressEntrySheet` (bottom sheet de creación, nota + fotos múltiples vía
`image_picker.pickMultiImage`).

**Identidad "¿soy el profesional asignado?"**: comparando `myProfessionalProfileProvider`
(`Professionals.referenceId` propio) contra `service.professional!.referenceId` — NUNCA contra
`sessionProvider`/`Users.referenceId` directo, son UUIDs de entidades distintas. El botón "Agregar
avance" y el botón de eliminar de cada entrada usan esta misma comparación.

**Corrección a la spec original, igual que en backend**: las fotos no viajan en el mismo POST que
crea la entrada — se suben antes vía `POST /uploads/image` (mismo endpoint/patrón que
`ProfileRepository.uploadAvatar`), y `ServiceProgressRepository.createEntry` solo manda las keys.

**Gap nuevo encontrado y resuelto**: ninguna pantalla de mobile resolvía todavía una key de S3 a
una URL mostrable (ni siquiera `Service.images`, que nunca se renderiza hoy) — se agregó
`ServiceProgressRepository.resolvePhotoUrl(key)` (`GET /uploads/presigned-url`) +
`serviceProgressPhotoUrlProvider`, resuelto fresco por widget (`autoDispose`), nunca persistido —
mismo criterio que `avatarKey`/`avatarUrl` (`.claude/rules/auth.md`).

**`editWindowExpired` calculado por el backend, no reimplementado en el cliente** — el
`ServiceProgressEntryResponseDTO` ya trae ese booleano calculado contra la hora del servidor; el
botón de eliminar simplemente lo lee, evitando el riesgo de desfasaje de reloj del dispositivo que
la spec ya marcaba como límite explícito.

**Pendiente, no cerrado en esta sesión**:
- Validación `PROGRESS_LOG_REQUIRED` al completar un servicio — no se tocó
  `service_transition_controller_provider.dart`/`professional_services_screen.dart`; el 400 ya
  llegaría con mensaje del backend vía el manejo genérico de `ServiceFailure`, pero no se agregó
  un caso específico ni un test para él. Tarea chica aparte.
- Checkpoint contra un dispositivo/emulador real — esta sesión solo corrió `flutter analyze`/
  `flutter test` (320/320 en verde, incluye 19 tests nuevos: 7 repositorio + 4 controller + 5
  timeline + 3 formulario), sin probar la app corriendo de verdad.

**Estado**: implementado y verificado (`flutter analyze` sin issues, `flutter test` 320/320).
Bitácora en Web (pestaña en `admin/services`) sigue sin implementar — no tocada en esta sesión.

## Fase 0007 — Documentos y antecedentes del profesional: implementado 2026-08-27

`lib/features/professional_documents/` completo — pantalla "Mis documentos" (profesional,
`/profesional/mis-documentos`, agregada a `_protectedPaths`/`_professionalGatedPaths`) y sección
"Documentos y antecedentes" del lado cliente (badge de verificación + certificaciones/portafolio
aprobados).

**No existe `lib/features/professionals/widgets/professional_profile_screen.dart`** — la spec de
esta fase decía "ya existe", pero se verificó grepeando el repo (no asumido) y ese screen nunca se
construyó; no hay ninguna pantalla de "perfil público de profesional" en mobile todavía. Se
embebió la sección del cliente en `service_detail_screen.dart` en su lugar — mismo punto de
contacto real que ya usa `ProgressTimeline` (Fase 0008) para mostrar info del profesional
asignado. Construir una pantalla de perfil público completa (con su propia navegación/discovery)
es un alcance mayor, no pedido en esta fase — backlog si se pide.

**`Professionals.verificationStatus` requirió una llamada nueva fuera de esta feature** —
`GET /professionals/:referenceId` (ya existe en el backend, sin consumidor en mobile hasta ahora)
es la única fuente del booleano "antecedentes verificados" (el endpoint público de documentos
filtra `BACKGROUND_CHECK` por `isVisibleToClient=false`, así que ese dato JAMÁS llega por ahí).
Se agregó `ProfessionalDocumentsRepository.isVerified()` scoped a esta feature (un solo campo),
en vez de armar una feature `professionals` completa sin que se haya pedido.

**Subida solo como foto (cámara/galería), no PDF nativo** — no hay `file_picker` en el proyecto
(`image_picker` no lee PDFs). Antecedentes/títulos se suben como foto del documento físico o
captura de pantalla, igual que la mayoría de flujos de verificación mobile. Si se necesita adjuntar
un PDF real, evaluar `file_picker` como tarea aparte (mantenimiento activo, no asumido acá).

**A diferencia de `service_progress`, el archivo viaja en el mismo POST** — el backend de esta
fase reusa `modules/storage` directo (no el endpoint genérico `/uploads/*`), así que
`ProfessionalDocumentsRepository.upload()` es un solo multipart con los campos + el archivo, sin
el paso de subida separada que sí necesitó la bitácora de trabajo.

**Tests**: 10 nuevos (4 repositorio + 2 controller + 4 widget). `flutter analyze`/`flutter test`
en verde (330/330).

**Pendiente, no cerrado en esta sesión**: Web (Fase 0001) — catálogo, cola de revisión, pestaña de
historial en el detalle de profesional.

**Corrección post-implementación (mismo día)**: `isVerified()` leía `verificationStatus`, campo
que resultó tener OTRO escritor ya existente en backend (aprobación manual de cuenta, sin relación
con documentos — ver `TekoApp-Backend/openspec/decisions.md`). Backend agregó un campo nuevo
(`requiredDocumentsVerified`) exclusivo para este derivado; `isVerified()` corregido para leerlo.
`flutter analyze`/`flutter test` en verde (330/330) tras el fix.

## Fase 0009 — Presupuestos multi-opción: implementado 2026-08-28

`lib/features/budgets/`. Ver `openspec/changes/0009-multi-option-budgets.md` para el detalle
completo de tareas y checkpoint pendiente.

**Decisión de flujo (confirmada leyendo el código real antes de implementar, per la instrucción
"revisar el flujo real de la Fase 0003 antes de decidir si es pantalla nueva o extensión")**: el
"proponerse" existente (`AvailableServicesScreen`) era un solo botón sin formulario (`POST
/services/:id/requests` vacío, sin `proposedPrice`) — se extiende (no se reemplaza) encadenando la
navegación a `BudgetBuilderScreen` apenas se crea la `ServiceRequest`. Del lado cliente, el botón
"Aceptar" directo de `_ServiceRequestsSection` se reemplaza por "Ver presupuestos" →
`BudgetComparisonScreen`, donde "Elegir esta opción" dispara la misma transacción de aceptación.

**Otras decisiones**:
- `RespondToRequestController` queda sin llamador pero no se borra — la capacidad de
  aceptar/rechazar una propuesta sin presupuesto es una decisión de producto aparte, no algo que
  correspondiera decidir al implementar esta fase.
- `TekoInput` ganó un `onChanged` opcional (no rompe usos existentes) — necesario para los campos
  editables del armado de presupuesto.
- Sin límite client-side de `maxBudgetOptionsPerRequest`: `Service.category` (resumen anidado) no
  expone ese número, así que el límite se comunica vía el 400 real del backend, no una validación
  adivinada.

**Estado**: implementado y verificado — `flutter analyze` (0 issues) + `flutter test` (345/345,
incluye 12 tests nuevos + 2 actualizados). Pendiente (no de código): checkpoint de negocio real con
los 3 repos corriendo juntos (a cargo de José, mismo criterio que fases anteriores).

## Fase 0010 — Contratos generados desde el presupuesto aceptado: implementado 2026-08-28

`lib/features/contracts/`. Ver `openspec/changes/0010-contracts-from-accepted-budget.md` para el
detalle de tareas.

**Decisiones explícitas de José (2026-08-28), coordinadas antes de implementar**:
- **Copy legal**: `contractDisclaimerText` en `l10n/{es,en}.arb` es un placeholder genérico
  marcado `TODO(legal)` en la metadata de `es.arb` — reemplazar por el texto legal real antes de
  producción, no asumir que este texto es definitivo.
- **PDF**: mobile solo VISUALIZA el PDF que genera el backend (`pdfmake`, ver decisions.md de
  Backend) — nunca lo genera del lado cliente. Se reusa `url_launcher` (ya dependencia del
  proyecto, mismo patrón que `professional_documents_section.dart`:
  `launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)`) para abrir la URL presignada
  en el visor de PDF nativo del sistema — se evaluó agregar un paquete de PDF embebido
  (`pdfx`/`flutter_pdfview`) y se descartó por no aportar valor real sobre abrir el archivo
  externamente, evitando una dependencia nueva y su configuración nativa.

**Enganchado al flujo de selección de presupuesto (Fase 0009)**: `BudgetComparisonScreen._select()`
ahora, tras un `select` exitoso, llama a `generateContractControllerProvider.generate()` y navega
directo a `ContractPreviewScreen` (`context.pushReplacement('/contratos/:referenceId')`) en vez de
solo volver al detalle del servicio — el flujo completo queda "elegir presupuesto → firmar
contrato" sin un paso manual intermedio.

**Brecha real encontrada y corregida en Backend antes de tocar Mobile** (no estaba en ninguna de
las 2 specs): el spec de Mobile pide explícitamente una pantalla "listado de contratos propios"
(`MyContractsScreen`), pero la spec de Backend solo definía `GET /contracts/:referenceId` (por
uno) y `GET /admin/contracts` (staff) — no había ningún endpoint para que un usuario viera SUS
contratos. Se agregó `GET /contracts` al backend (ver `TekoApp-Backend/openspec/decisions.md`,
Fase 0004) antes de construir esta pantalla, en vez de dejarla sin dónde apoyarse.

**Segunda extensión de Backend, motivada por la copy de estado que pide esta misma spec**
("Pendiente de tu firma" / "Pendiente de la firma de la otra parte"): el DTO de contrato no
exponía ningún dato para que el cliente supiera si el usuario actual es el cliente o el
profesional del contrato (a propósito, para no exponer `clientUserId`/`professionalId`). Se agregó
`viewerRole: 'CLIENT' | 'PROFESSIONAL'` a `ContractResponseDTO`, calculado server-side — sin esto,
la UI no podía distinguir "te toca a vos" de "le toca a la otra parte" con la información que ya
tenía.

**Widget único parametrizado por rol** (como pide la spec): `ContractPreviewScreen` no bifurca por
rol explícitamente — `Contract.isPendingViewerSignature` (getter derivado de `viewerRole` +
`status`) decide si mostrar el formulario de firma, siendo el mismo widget para cliente y
profesional.

**Tests**: 16 nuevos — `contracts_repository_test.dart` (6: generar, obtener, firmar, 409,
resolver URL de PDF, listar propios), `generate_contract_controller_provider_test.dart` (2),
`sign_contract_controller_provider_test.dart` (2, incluye el 409 de firma fuera de turno/
duplicada), `contract_preview_screen_test.dart` (4: pendiente de tu firma, pendiente de la otra
parte, firmado con PDF disponible, firmar habilitando el botón solo con nombre+checkbox completos)
y `my_contracts_screen_test.dart` (2). Se actualizó `budget_comparison_screen_test.dart` para
reflejar la navegación nueva tras seleccionar (mismo criterio que la Fase 0009 con
`available_services_screen_test.dart`/`service_detail_screen_test.dart`: reescribir `_pumpScreen`
con `MaterialApp.router` + `GoRouter` real).

**Bug de test encontrado y corregido al escribir el widget test**: el `CheckboxListTile` de la
firma, anidado dentro de `TekoCard` (un `DecoratedBox` con fondo/borde), disparaba la advertencia
de Flutter "ListTile background color or ink splashes may be invisible" — tratada como excepción
fatal por el test framework. Fix: envolver el `CheckboxListTile` en `Material(type:
MaterialType.transparency, ...)`, patrón estándar de Flutter para este caso.

**Estado**: implementado y verificado — `flutter analyze` (0 issues) + `flutter test` (361/361).
Pendiente (no de código): checkpoint de negocio real (cliente y profesional firmando un contrato
real de punta a punta) — a cargo de José, mismo criterio que fases anteriores.

## `API_BASE_URL` de CI/CD apuntando a placeholders/localhost — corregido 2026-08-28

**Encontrado al preguntar José** ("¿la compilación de develop apunta bien a los datos ya
publicados en Render?") — no apuntaba. Verificado leyendo `.github/workflows/build.yml` y
`.github/workflows/release.yml` real, no asumido:

- `build.yml` (builds de validación manuales): `API_BASE_URL_QA`/`API_BASE_URL_PROD` apuntaban a
  `qa-api.tekoapp.com.py`/`api.tekoapp.com.py` — dominios que nunca se configuraron.
  `API_BASE_URL_DEV` apuntaba a `10.0.2.2` (alias del emulador a localhost) — solo funciona si el
  backend corre en la misma PC.
- **Bug más serio, en `release.yml`** (los releases REALES que un tester sideloadea, la base
  entera de la Fase 0015): este workflow **nunca había pasado `--dart-define=API_BASE_URL` en
  ningún build**, ni Android ni iOS — todo release publicado hasta ahora (todos los tags
  `v1.0.0-develop.N`/`-qa.N` existentes) quedó compilado con el default hardcodeado de
  `Env.apiBaseUrl` (`10.0.2.2`), inservible en un dispositivo real. No se había notado porque
  nadie había sideloadeado un release real en un dispositivo fuera de un emulador con backend
  local — recién se iba a notar de verdad cuando alguien probara la Fase 0015 en la práctica.

**Confirmado con José**: backend real en Render, `https://tekoapp-backend.onrender.com` (verificado
con `curl` contra `/tekoapp-backend/api/healthcheck` → `200`). Web real en Vercel,
`https://teko-app-frontend-web.vercel.app` (no se toca en este repo, solo para contexto). Los 3
ambientes (`dev`/`qa`/`prod`) de Mobile apuntan HOY a esa misma instancia de Render — no existe
todavía un backend/DB separado por ambiente (decisión explícita de José, "por ahora qa y prod
usarán el mismo"; dev también, para que un release real con tag `dev` sea sideloadeable y
funcional, no solo el de `qa`/`prod`).

**Fix**: `API_BASE_URL_DEV`/`API_BASE_URL_QA`/`API_BASE_URL_PROD` en `build.yml` actualizados a la
URL real de Render. `release.yml` — agregado `env.API_BASE_URL` a nivel de workflow + pasado a los
3 builds que antes no lo tenían (`build-android` con APK y AAB, `build-ios` con IPA, este último
con su propia resolución de `APP_ENVIRONMENT` vía `github.ref_name` ya que corre en un job
separado sin acceso al `steps` de `build-android`).

**Pendiente futuro, no bloqueante**: cuando `qa`/`prod` tengan su propio backend/DB desplegado
(separado del compartido de hoy), actualizar `API_BASE_URL_QA`/`API_BASE_URL_PROD` — la estructura
de 3 variables separadas ya está lista para eso, solo hay que cambiar el valor.

## id/referenceId estandarizado — implementado 2026-08-28 (backlog post-Fase 0004, ítem 1)

Ver `TekoApp-Backend/openspec/changes/0008-id-referenceid-standardization.md` para el cambio de
contrato del backend. Migración de los 5 modelos afectados en este repo: `Service`,
`ServiceRequest`, `Payment`, `PaymentMethod`, `Rating`. Antes, `id` (String) YA ERA el `referenceId`
(UUID) porque el backend lo sobreescribía — ahora el backend expone `id` (int, PK interna, solo
ordenamiento) y `referenceId` (String, UUID) por separado. Cambio breaking sin shim, coordinado con
el fix del backend en la misma sesión.

- Los 5 modelos (`lib/features/{services,payments,ratings}/models/*.dart`) cambiaron `id` de
  `String` a `int` y agregaron `referenceId` (`String`) nuevo, parseado desde `json['referenceId']`.
- Toda navegación/lookup/URL que usaba `.id` de estos 5 tipos migró a `.referenceId` — proveedores,
  pantallas y sus tests. Las referencias a OTRAS entidades (ej. `Payment.serviceId`,
  `Rating.serviceId`) NO cambiaron — ya eran el `referenceId` (UUID) del padre, comportamiento
  preexistente sin relación con este ítem.
- **2 bugs de navegación reales encontrados durante la migración, no anticipados en el alcance**:
  `payment_history_screen.dart` (`context.push('/pagos/historial/${payment.id}')`) y
  `my_services_screen.dart` (`context.push('/mis-servicios/${service.id}')`) armaban la ruta con
  `.id` — con el contrato viejo esto funcionaba porque `id` era el UUID, pero con el nuevo contrato
  hubiera roto la navegación en producción (Int en vez de UUID en la URL). Ninguno de los dos
  archivos apareció en el barrido inicial de call sites — se encontraron recién al ver fallar sus
  tests de widget tras el cambio de tipo. Corregidos a `.referenceId` en ambos (Key del tile +
  ruta).
- Migración ejecutada en dos pasadas: un primer intento con un agente en paralelo se cortó a mitad
  de camino por límite de sesión, dejando ~30 fixtures JSON de test sin actualizar (todavía con
  `'id': '<uuid>'` string en vez de `'id': <int>` + `'referenceId': '<uuid>'`) y sin tocar los 2
  bugs de navegación de arriba — se completó a mano verificando cada error real de
  `flutter analyze`/`flutter test`, no repitiendo el barrido de call sites desde cero.

**Verificado**: `flutter analyze` 0 issues, `flutter test` 375/375.

## Branding centralizado — revisado 2026-08-28 (backlog post-Fase 0004, ítem 5), sin cambios de código en este repo

Ver `TekoApp-Frontend-Web/BRANDING.md` para el documento completo (cubre los 2 repos). Resumen del
lado Mobile:

- El nombre visible en runtime (`appTitle` en `lib/l10n/{es,en}.arb`, usado vía `onGenerateTitle`
  en `lib/app.dart`) YA es una sola fuente — no hay gap ahí, no se tocó nada.
- El gap real es el nombre/paquete/bundle ID repetido a mano en **6 archivos de configuración
  nativa/build** (`pubspec.yaml`, `android/app/build.gradle.kts`, `AndroidManifest.xml`, el
  paquete Kotlin de `MainActivity.kt`, `ios/Runner/Info.plist` — `ios/Flutter/AppFrameworkInfo.plist`
  es un placeholder de Flutter, no específico de esta app, no cuenta). **No es centralizable en
  runtime a propósito**: `applicationId`/bundle ID son la identidad de la app en las stores —
  cambiarlos después de publicar equivale a publicar una app nueva (pierde reviews, instalaciones,
  la asociación con la key de Play App Signing). Documentado como proceso manual paso a paso en
  `BRANDING.md`, no como código — automatizarlo (ej. un script de rename) recién tendría sentido si
  este proceso se repite más de una vez, cosa que no pasó todavía.
- Ítem cerrado sin ningún archivo de este repo modificado — `flutter analyze`/`flutter test` sin
  cambios respecto al estado ya verificado en la sección anterior.

## Ratings — anonimato real + KPIs — implementado 2026-08-28 (backlog post-Fase 0004, ítem 3)

Ver `TekoApp-Backend/openspec/changes/0009-ratings-anonymity-and-kpis.md` para el fix completo del
lado backend (`isAnonymous` nunca se aplicaba, `GET /ratings` sin guard, bug real en
`aggregateUserStats`, y un leak más severo de PII completa en `GET /professionals/:id/reviews`).
Lado Mobile: 2 pantallas nuevas de KPIs, sin identidad de quién/cuándo.

- `lib/features/ratings/models/{user_rating_stats,professional_rating_stats}.dart` — nuevos.
- `ratings_repository.dart` — `fetchMyStats()` (`GET /ratings/me/stats`, resuelve el userId desde
  el token — Mobile nunca conoce su propio id interno, `GET /auth/scope` no lo expone) y
  `fetchProfessionalStats(int professionalId)` (`GET /ratings/professional/:id/average`, sí pide
  el id interno porque `Professionals` ya expone `id`+`referenceId` por separado desde antes de la
  Fase 0008 — se reusa `myProfessionalProfileProvider.id`, sin necesidad de un endpoint "me"
  equivalente para este caso).
- `MyRatingStatsScreen` (`/mis-calificaciones`, cliente) y `ProfessionalRatingStatsScreen`
  (`/profesional/mis-calificaciones`, profesional gateado) — accesos rápidos agregados en
  `home_screen.dart`/`professional_home_screen.dart`.
- Traducido es/en desde el primer commit de la feature (`myRatingStats*`/`professionalRatingStats*`
  en `es.arb`/`en.arb`).

**Verificado**: `flutter analyze` 0 issues, `flutter test` 381/381 (6 nuevos: 2 de repositorio +
2 por pantalla).

## Ratings — anonimato real + KPIs (Web) — implementado 2026-08-28

Del lado de Web (otro repo, documentado acá por completitud del ítem 3 del backlog): se agregó
`ProfessionalRatingStatsCard` (`/pro/calificaciones`, arriba de `ReviewsTable`) y
`MyRatingStatsCard` (`(client)/page.tsx`, home del cliente) — ambas reusan los mismos 2 endpoints
que Mobile. Detalle completo en `TekoApp-Frontend-Web/openspec/decisions.md`.

## Propinas — implementado 2026-08-28 (backlog post-Fase 0004, ítem 2)

Ver `TekoApp-Backend/openspec/changes/0010-tips.md` para el diseño completo del backend (entidad
`Tips` separada, nunca fusionada a `Payment.totalAmount` ni a la comisión de la plataforma).

- `lib/features/payments/models/{tip,tip_mode}.dart` — nuevos. `TipMode` solo declara
  `percentage`/`fixed`/`free` — la UI solo ofrece `percentage` (chips) y `free` (monto libre);
  `fixed` existe en el dominio/backend pero no tiene una config de montos preestablecidos
  todavía, así que no se expone ningún control propio para elegirlo.
- `payments_repository.dart` — `fetchTipConfig()` (`GET /tips/config`) y `createTip(...)`
  (`POST /payments/:id/tip`).
- `TipDialog` (`tip_dialog.dart`) — chips de porcentaje sugerido + input de monto libre, se abre
  desde un botón "Dejar propina" en `payment_detail_screen.dart` (solo visible si el pago está
  `completed`/`paid` y todavía no tiene propina). La propina ya dejada se muestra como texto en
  vez del botón.
- `payment_history_screen.dart` — ícono con tooltip (`Icons.volunteer_activism_outlined`) junto al
  monto cuando el pago tiene propina, cumpliendo "visible en detalle Y listado" del backlog
  original.
- `Payment.tip` (nullable) agregado al modelo, poblado automáticamente porque el backend ahora
  incluye `tip` en el `include` compartido de `GET /payments`/`GET /payments/:id` — sin cambios
  de red adicionales del lado Mobile.

**Verificado**: `flutter analyze` 0 issues, `flutter test` 388/388 (7 nuevos: 3 de repositorio +
4 de pantalla/diálogo).

## Propinas (Web) — implementado 2026-08-28

Del lado de Web (otro repo, documentado acá por completitud): a diferencia de Mobile, Web **no**
tiene ninguna pantalla donde un cliente pague/vea sus propios pagos — el módulo de pagos de Web es
100% admin/staff (`/admin/payments`). Por eso Web solo agrega visualización de SOLO LECTURA de la
propina (monto en el detalle, ícono con tooltip en la tabla) — ningún botón para dejar una, ya que
el staff nunca es el cliente que pagó. Detalle completo en
`TekoApp-Frontend-Web/openspec/decisions.md`.
