# Spec: Registro de usuarios y recuperación de cuenta (Mobile)

Backend: `TekoApp-Backend/openspec/specs/user-registration-and-account-emails.md` (leer primero).
Web: `TekoApp-Frontend-Web/openspec/specs/user-registration-and-account-recovery.md` (mismo
backend, mismas rutas de link de email — mobile NO reimplementa las pantallas de confirmación por
token, ver "Decisión: reset/verify se completan en el navegador" abajo).

## Objetivo

Hoy `lib/features/auth/` solo tiene login — no hay forma de registrarse ni recuperar contraseña
desde la app. Agregar el registro y el disparo de recuperación de contraseña, manteniendo el mismo
contrato de cifrado RSA-OAEP que ya usa `login_screen.dart`.

## Alcance

**Incluye**: pantalla de registro, pantalla de "olvidé mi contraseña" (dispara el email, sin
pantalla de confirmación por token — ver decisión abajo), links desde `login_screen.dart`.

**No incluye**: pantalla de confirmación de reseteo con token (`?token=&email=`) ni de
verificación de email con token — mobile no tiene deep-linking configurado hoy (limitación ya
documentada en `openspec/project.md` para otros flujos), así que esos 2 pasos se completan en el
navegador del dispositivo vía las páginas de `TekoApp-Frontend-Web`, no dentro de la app.

## Decisión: reset/verify se completan en el navegador, no en la app

El email de recuperación/verificación linkea a una URL de `TekoApp-Frontend-Web`
(`/auth/reset-password?token=&email=` / `/auth/verify-email/confirm?token=&email=`) — abrir ese
link desde el dispositivo (mail app → browser del sistema) ya funciona sin ningún código nuevo acá,
porque son URLs http normales. Construir un deep link nativo (`tekoapp://reset-password?...`) que
abra la app en la pantalla de confirmación es un alcance mayor (requiere configurar Universal
Links/App Links en ambas plataformas) — explícitamente fuera de esta fase, backlog futuro si se
pide.

## Pantallas nuevas (`lib/features/auth/widgets/`)

- `register_screen.dart` — mismos campos que `POST /onboarding` (nombre, apellido, email,
  teléfono, password, confirmar password, checkbox `acceptTerms`) — cifrado RSA-OAEP con el mismo
  helper que ya usa `login`. Tras éxito: pantalla/mensaje "revisá tu correo para verificar tu
  cuenta", sin asumir auto-login (mismo riesgo documentado en la spec de backend).
- `forgot_password_screen.dart` — pide email, dispara `POST /auth/email/send-password-reset`,
  mensaje genérico (nunca confirmar/negar si el email existe).
- `login_screen.dart` (existente) — agregar 2 acciones: "Crear cuenta" → `/registro`,
  "¿Olvidaste tu contraseña?" → `/recuperar-contrasena`.

## Rutas nuevas (`go_router`, `app.dart`)

`/registro` y `/recuperar-contrasena` — mismo patrón que `/login` (fuera de `_protectedPaths`, sin
guard de sesión).

## `data`/`providers` nuevos

- `RegisterController` (`AsyncNotifier<void>`) — mismo patrón que `LoginController`: cifra con el
  helper RSA-OAEP existente, llama `AuthRepository.register(...)`.
- `ForgotPasswordController` (`AsyncNotifier<void>`) — llama `AuthRepository.requestPasswordReset(email)`.
- Extender `AuthRepository` (no crear un repositorio paralelo) con `register(...)` y
  `requestPasswordReset(email)` — mismo cliente HTTP, mismos interceptors ya configurados.

## Fuera de alcance de esta spec

Deep linking nativo para completar reset/verify dentro de la app (ver decisión arriba), onboarding
de profesional (ya existe).

## Riesgos / límites explícitos

- Mismo riesgo que la spec de backend: si `GET /auth/user-verify` requiere sesión activa y el
  registro no logueó al usuario, un usuario que verifica desde OTRO dispositivo (no el que usó
  para registrarse) puede fallar — visible solo del lado Web (mobile no implementa esa pantalla),
  pero afecta el mensaje que esta pantalla de registro le muestra al usuario ("revisá tu correo" no
  debe prometer que cualquier dispositivo funcionará si no está confirmado).
