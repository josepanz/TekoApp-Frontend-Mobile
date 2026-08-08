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

## Qué NO se decidió todavía (pendiente explícito, no un olvido)

- Implementación del flujo de login real (nonce + RSA-OAEP + almacenamiento de tokens) — el
  mecanismo ya está decidido y verificado contra el backend real (ver las secciones específicas
  más arriba), el código en sí es tarea de la Fase 0002.
- Offline-first vs. online-only: no se decidió si la app necesita funcionar sin conexión (ej. ver
  servicios ya cargados) — el dominio (servicios en tiempo real, ubicación en vivo) sugiere que
  online-only es razonable para el MVP, pero es una decisión de producto, no técnica, que falta
  confirmar con el negocio antes de la Fase 3.
- Firma de release y publicación en Google Play / App Store — bloqueado por no tener las cuentas
  todavía, no por falta de decisión técnica (ver "CI/CD" arriba).
