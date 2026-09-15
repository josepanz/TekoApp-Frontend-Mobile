# Spec: Login biométrico (Mobile)

Plan de fase: `openspec/changes/platform-hardening-2026-09/WORKPLAN.md`, tarea I-05. Solo spec —
sin implementación (ver instrucción explícita de la tarea).

## Objetivo

El login (`AuthRepository.login`, ver `auth_repository.dart`) pide `GET /auth/public-key` +
`POST /auth/nonce` + cifrado RSA-OAEP de `{password, nonce}` + `POST /auth/login` — más fricción
que el login promedio de una app móvil (usuario+contraseña simple o un botón biométrico). Mejora
retención (menos abandono al tener que re-tipear credenciales), no arregla nada roto.

## Hallazgo de la verificación previa que acota el alcance real

**La fricción de este login NO ocurre en cada apertura de la app** — verificado en
`session_provider.dart`: al arrancar, si hay un `accessToken` guardado (aunque esté vencido),
`SessionNotifier._restoreSession()` llama `GET /auth/scope` directo; si ese 401 dispara,
`RefreshTokenInterceptor` ya refresca solo contra la cookie `refreshToken` persistida
(`PersistCookieJar`/`SecureCookieStorage`, ver `cookie_jar_provider.dart`). El usuario que cierra y
reabre la app normalmente **ya vuelve a estar autenticado sin ver la pantalla de login** — cero
fricción hoy en ese caso.

El login nonce+RSA con fricción real solo aparece en 3 casos: (a) el primer login de una cuenta en
el dispositivo, (b) después de un logout explícito, (c) cuando el propio refresh token expiró o
fue revocado (ausencia larga, o el backend lo invalidó). El biométrico solo puede ayudar en (b) —
en (a) y (c) no hay ninguna sesión previa que "restaurar" con biometría, así que tampoco hay nada
que este feature pueda saltear ahí.

## Decisión: qué hace el biométrico exactamente

**No es un dispositivo de segundo factor contra el backend** — es una conveniencia local: tras un
logout explícito (o un refresh token vencido), en vez de retipear email+contraseña, el usuario
puede autenticarse con huella/rostro (`local_auth`) para que la app repita el flujo COMPLETO de
login (public-key → nonce → cifrado → `POST /auth/login`) usando una contraseña guardada
localmente — el backend nunca se entera de que hubo biometría, solo recibe el mismo login de
siempre.

**Alternativa descartada para esta fase**: un esquema tipo WebAuthn/passkey (par de claves
device-bound, la privada nunca sale del secure enclave, el backend verifica una firma de challenge
en vez de una contraseña) es la forma "correcta" de hacer esto sin guardar la contraseña en
ningún lado — pero requiere 2 endpoints nuevos en `TekoApp-Backend` (registrar clave pública del
dispositivo, verificar challenge firmado) que no existen hoy. Bloquearía esta feature detrás de
trabajo de backend no pedido en esta tarea (I-05 es BAJO, "mejora retención, no arregla nada roto"
— no justifica ese alcance). Documentado acá para que quede a la vista si en el futuro se decide
subir el nivel de seguridad de este feature.

## Decisión: sí guardar la contraseña, con el mismo modelo de confianza que ya usa el repo

Guardar la contraseña en texto plano localmente suena mal en abstracto, pero **es exactamente el
mismo trust boundary que ya usa este repo hoy** para el `accessToken` y la cookie `refreshToken`:
`flutter_secure_storage`, respaldado por Keychain (iOS)/Keystore+EncryptedSharedPreferences
(Android). No es una excepción nueva ni un estándar más débil — es el mismo mecanismo, un campo
más. La diferencia real de riesgo es de IMPACTO si se compromete: un `accessToken`/`refreshToken`
robado da sesión, una contraseña robada da la cuenta completa (y si el usuario reusa esa
contraseña en otro servicio, más que eso) — por eso el gate biométrico ADICIONAL antes de leerla
(no alcanza con que esté en secure storage, hay que pedir biometría cada vez que se usa para
login, no solo al guardarla).

**Opt-in explícito, nunca default**: ofrecer activarlo (switch en `profile_screen.dart`, o un
prompt post-login exitoso "¿Activar ingreso con huella/rostro?") — nunca guardarla sin que el
usuario lo pida.

## Diseño

- Dependencia nueva: `local_auth` (no está en `pubspec.yaml` hoy) — verificar mantenimiento activo
  y compatibilidad con el `compileSdk`/AGP actual al implementar, mismo criterio que
  `app-version-update.md` aplicó para su elección de paquete (no fijar versión ahora, confirmar
  recién al implementar).
- `lib/core/auth/biometric_login_service.dart` (nuevo): wrapper sobre `local_auth` —
  `canAuthenticate()` (el dispositivo tiene biometría enrolada), `authenticate()` (dispara el
  prompt nativo).
- Almacenamiento: 2 claves nuevas en `flutter_secure_storage` (mismo servicio ya inyectado en
  `AuthRepository`) — el email y la contraseña, escritas SOLO cuando el usuario activa el opt-in
  tras un login exitoso. `AuthRepository.clearSession()` (logout) **no** debe borrar estas 2
  claves — son justamente para sobrevivir al logout. Sí se debe poder desactivar el feature a mano
  (switch en perfil) y ahí sí borrarlas.
- Flujo en la pantalla de login: si hay credenciales guardadas para biometría, mostrar un botón
  adicional "Ingresar con huella/rostro" junto al form de email+contraseña (no reemplazarlo — el
  usuario siempre puede tipear igual). Al tocarlo: `authenticate()` → si aprueba, leer
  email+contraseña guardados → `AuthRepository.login(email, password)` (el mismo método de
  siempre, sin un camino paralelo) → `sessionProvider.refreshAfterLogin()`.
- Si `authenticate()` falla o el usuario cancela: quedarse en el form normal, sin mensaje de error
  alarmante (cancelar un prompt biométrico es una acción válida, no una falla).

## Fuera de alcance de esta spec

Esquema WebAuthn/passkey (ver decisión arriba), biometría como segundo factor real contra el
backend, biometría para desbloquear la app sin recargar sesión (app-lock local sin tocar el
backend — feature distinta, no pedida acá), soporte de PIN/patrón como fallback si el dispositivo
no tiene biometría enrolada (más allá del fallback nativo que `local_auth` ya ofrece por SO).

## Riesgos / límites explícitos

- **Guardar una contraseña en claro (aunque sea en secure storage) es una superficie de ataque
  real** si el dispositivo se compromete a fondo (root/jailbreak con acceso a Keychain/Keystore) —
  mismo riesgo ya aceptado hoy para el `accessToken`/`refreshToken`, pero el IMPACTO de este campo
  específico es mayor (la cuenta completa, no solo una sesión). Aceptado como opt-in explícito, no
  como default — el usuario decide ese trade-off, no la app por él.
- **Reutilización de contraseña**: si el usuario reusa esta contraseña en otro servicio, un
  compromiso de este dispositivo expone más que la cuenta de TekoApp. Fuera del control de esta
  spec — mismo riesgo inherente a cualquier app que pida contraseña, no específico de este feature.
- **Sin revocación remota**: si el usuario pierde el dispositivo, borrar la sesión desde otro lado
  (no existe esa función hoy — fuera de alcance) no invalida la contraseña guardada localmente en
  el dispositivo perdido. Mismo límite que cualquier "recordar contraseña" de cualquier app; se
  mitiga con el PIN/biometría del propio SO del dispositivo, no algo que esta feature pueda
  resolver del lado servidor.
