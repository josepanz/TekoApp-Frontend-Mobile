# CP-AUTH — Auth y sesión (e2e de widgets con Dio mockeado + flujos Maestro contra backend e2e)

Repo: Mobile (MOB). Trazabilidad: plan maestro M1 (Auth y sesión).

## CP-MOB-AUTH-001 — Login, home, Mi perfil y logout de punta a punta

| Campo | Contenido |
|---|---|
| Título | Completa el ciclo login -> home -> Mi perfil -> logout con la app real y Dio mockeado |
| Tipo / Nivel | e2e (widgets; no es Maestro) |
| Prioridad | P0 |
| Trazabilidad | M1 Auth/Sesión; nonce + RSA -> login; logout limpia la sesión |
| Precondiciones | `TekoApp` montada; Dio mockeado (nonce, login, perfil, logout); par de claves RSA generado en el test (nunca la clave real del backend); `flutter_secure_storage` y `shared_preferences` mockeados; providers de push FCM sobreescritos (no-op) |
| Pasos | 1. Abrir la app sin sesión y ver `LoginScreen`. 2. Completar email y contraseña y enviar. 3. Verificar la llegada a `HomeScreen`. 4. Navegar a Mi perfil (`ProfileScreen`). 5. Ejecutar logout. 6. Verificar el regreso a login. |
| Datos de prueba | Credenciales y respuestas simuladas definidas en el test (sin secretos reales) |
| Resultado esperado | Navegación Login -> Home -> Perfil -> Login; la sesión se limpia al cerrar sesión |
| Automatizado en | `test/e2e/login_profile_logout_test.dart` — `login -> home -> Mi perfil -> logout de punta a punta` |

Nota: el equivalente real contra backend local son los flujos Maestro CP-MOB-AUTH-003..008 de abajo.

## CP-MOB-AUTH-002 — Home expone un acceso a Mi perfil (DEF-MOB-AUTH-001)

| Campo | Contenido |
|---|---|
| Título | Home expone un acceso a Mi perfil (DEF-MOB-AUTH-001) |
| Tipo / Nivel | widget |
| Prioridad | P0 |
| Trazabilidad | M1; DEF-MOB-AUTH-001 (la ruta `/perfil` existía pero ningún widget navegaba a ella: logout y Mi perfil eran inalcanzables); id `home.home.profile_button` |
| Precondiciones | Home montada con sesión fixture |
| Pasos | 1. Montar `HomeScreen`. 2. Verificar el id semántico. 3. Tocar el ícono de perfil. |
| Datos de prueba | Usuario fixture del test |
| Resultado esperado | Navega a `/perfil` y el nodo `home.home.profile_button` existe |
| Automatizado en | `test/features/home/widgets/home_screen_test.dart` — `el ícono de perfil navega a /perfil y expone el id E2E (CP-MOB-AUTH-002)` |

## CP-MOB-AUTH-003 — Login correcto con cliente_a llega a Home

| Campo | Contenido |
|---|---|
| Título | Login correcto con cliente_a llega a Home |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P0 |
| Trazabilidad | M1 login (nonce + RSA); smoke Mobile |
| Precondiciones | Backend e2e en `:3100` con seed (`pnpm e2e:up && pnpm e2e:seed && pnpm e2e:serve` en el repo Backend); APK debug compilado con `dart_defines.e2e.json`; dispositivo o emulador Android; `clearState` al iniciar el flujo |
| Pasos | 1. Abrir la app limpia. 2. Escribir email y contraseña. 3. Tocar Entrar. 4. Declinar el opt-in biométrico si aparece. |
| Datos de prueba | `cliente_a@e2e.tekoapp.local` / `E2e-Passw0rd!` |
| Resultado esperado | Home visible con `Hola, Cliente` y el CTA `home.home.request_service_cta` |
| Automatizado en | Automatizado en: `.maestro/m1-login-ok.yaml`. Estado: **pendiente de ejecución: sin dispositivo** |

## CP-MOB-AUTH-004 — Rechaza login con credenciales inválidas

| Campo | Contenido |
|---|---|
| Título | Rechaza login con credenciales inválidas |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P0 |
| Trazabilidad | M1 matriz de error de auth |
| Precondiciones | Backend e2e en `:3100` con seed (`pnpm e2e:up && pnpm e2e:seed && pnpm e2e:serve` en el repo Backend); APK debug compilado con `dart_defines.e2e.json`; dispositivo o emulador Android; `clearState` al iniciar el flujo |
| Pasos | 1. Abrir la app limpia. 2. Email de cliente_a con contraseña incorrecta. 3. Tocar Entrar. |
| Datos de prueba | `cliente_a@e2e.tekoapp.local` / `Contrasena-Incorrecta-1` |
| Resultado esperado | `auth.login.error_message` visible con `Email o contraseña incorrectos`; no se llega a Home |
| Automatizado en | Automatizado en: `.maestro/m1-login-invalido.yaml`. Estado: **pendiente de ejecución: sin dispositivo** |

## CP-MOB-AUTH-005 — Registra un usuario nuevo

| Campo | Contenido |
|---|---|
| Título | Registra un usuario nuevo |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P1 |
| Trazabilidad | M1 registro |
| Precondiciones | Backend e2e en `:3100` con seed (`pnpm e2e:up && pnpm e2e:seed && pnpm e2e:serve` en el repo Backend); APK debug compilado con `dart_defines.e2e.json`; dispositivo o emulador Android; `clearState` al iniciar el flujo |
| Pasos | 1. Ir a Crear cuenta desde Login. 2. Completar nombre, apellido, email, teléfono y contraseña (dos veces). 3. Aceptar términos. 4. Enviar. |
| Datos de prueba | Email generado por JS de Maestro: `maestro_<epoch>@e2e.tekoapp.local`; contraseña `E2e-Passw0rd!` |
| Resultado esperado | Vuelve a Login con el aviso `Cuenta creada ...` (el alta exige verificar el email antes de iniciar sesión) |
| Automatizado en | Automatizado en: `.maestro/m1-registro.yaml`. Estado: **pendiente de ejecución: sin dispositivo** |

## CP-MOB-AUTH-006 — Cierra sesión y vuelve a Login

| Campo | Contenido |
|---|---|
| Título | Cierra sesión y vuelve a Login |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P0 |
| Trazabilidad | M1 logout invalida la sesión |
| Precondiciones | Backend e2e en `:3100` con seed (`pnpm e2e:up && pnpm e2e:seed && pnpm e2e:serve` en el repo Backend); APK debug compilado con `dart_defines.e2e.json`; dispositivo o emulador Android; `clearState` al iniciar el flujo; depende de CP-MOB-AUTH-002 (acceso a perfil) |
| Pasos | 1. Login. 2. Tocar el ícono de perfil. 3. Bajar hasta Cerrar sesión y tocarlo. |
| Datos de prueba | `cliente_a@e2e.tekoapp.local` / `E2e-Passw0rd!` |
| Resultado esperado | Pantalla de Login visible; Home ya no es accesible |
| Automatizado en | Automatizado en: `.maestro/m1-logout.yaml`. Estado: **pendiente de ejecución: sin dispositivo** |

## CP-MOB-AUTH-007 — Cambia de modo cliente a profesional y vuelve

| Campo | Contenido |
|---|---|
| Título | Cambia de modo cliente a profesional y vuelve |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P1 |
| Trazabilidad | M1 cambio de modo |
| Precondiciones | Backend e2e en `:3100` con seed (`pnpm e2e:up && pnpm e2e:seed && pnpm e2e:serve` en el repo Backend); APK debug compilado con `dart_defines.e2e.json`; dispositivo o emulador Android; `clearState` al iniciar el flujo; usuario con perfil profesional aprobado |
| Pasos | 1. Login como pro_aprobado. 2. Tocar el ícono de modo profesional. 3. Verificar Modo profesional. 4. Tocar Volver a modo cliente. |
| Datos de prueba | `pro_aprobado@e2e.tekoapp.local` / `E2e-Passw0rd!` |
| Resultado esperado | Se ve `professional.home.online_switch` en modo profesional y Home de cliente al volver |
| Automatizado en | Automatizado en: `.maestro/m1-cambio-modo.yaml`. Estado: **pendiente de ejecución: sin dispositivo** |

## CP-MOB-AUTH-008 — La sesión persiste tras reabrir la app

| Campo | Contenido |
|---|---|
| Título | La sesión persiste tras reabrir la app |
| Tipo / Nivel | e2e (Maestro) |
| Prioridad | P0 |
| Trazabilidad | M1 persistencia de sesión (refresh token en secure storage) |
| Precondiciones | Backend e2e en `:3100` con seed (`pnpm e2e:up && pnpm e2e:seed && pnpm e2e:serve` en el repo Backend); APK debug compilado con `dart_defines.e2e.json`; dispositivo o emulador Android; `clearState` al iniciar el flujo |
| Pasos | 1. Login. 2. Cerrar la app (`stopApp`). 3. Reabrir sin limpiar estado. |
| Datos de prueba | `cliente_a@e2e.tekoapp.local` / `E2e-Passw0rd!` |
| Resultado esperado | Entra directo a Home sin pasar por Login |
| Automatizado en | Automatizado en: `.maestro/m1-sesion-persistida.yaml`. Estado: **pendiente de ejecución: sin dispositivo** |

## Defectos asociados

| ID | Severidad | Detectado en | Descripción | Estado |
|---|---|---|---|---|
| DEF-MOB-AUTH-001 | P0 (bloquea logout y Mi perfil) | preparación de CP-MOB-AUTH-006 | `/perfil` no tenía ningún punto de entrada en la UI | Corregido: ícono `home.home.profile_button` en el AppBar de Home; cubierto por CP-MOB-AUTH-002 |
