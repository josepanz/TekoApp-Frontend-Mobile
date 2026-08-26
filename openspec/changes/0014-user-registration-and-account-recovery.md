# Fase 0014 — Registro de usuarios y recuperación de cuenta

Spec de diseño, NO implementada todavía. Contrato completo:
`openspec/specs/user-registration-and-account-recovery.md`.

## Antes de empezar

Leer `openspec/specs/user-registration-and-account-recovery.md` completo, en particular la
decisión de NO implementar pantallas de confirmación por token (reset/verify se completan en el
navegador vía `TekoApp-Frontend-Web`).

## Objetivo

Agregar registro y disparo de recuperación de contraseña a la app, extendiendo `AuthRepository`
existente — sin duplicar el cliente HTTP ni el cifrado RSA-OAEP ya resueltos para login.

## Tareas

- [ ] Extender `AuthRepository` con `register(...)`/`requestPasswordReset(email)`.
- [ ] `RegisterController`/`ForgotPasswordController` (`AsyncNotifier<void>`).
- [ ] `register_screen.dart`/`forgot_password_screen.dart`.
- [ ] Rutas `/registro`/`/recuperar-contrasena` en `app.dart` (fuera de `_protectedPaths`).
- [ ] Links cruzados en `login_screen.dart`.
- [ ] Traducir a es/en.
- [ ] Tests: repositorio (registro ok, email duplicado → error correcto), controllers, widgets
      (validación de formulario, estado de éxito/error).
- [ ] `flutter analyze`, `flutter test` en 0 issues.

## Checkpoint de salida

- [ ] Un usuario nuevo se registra desde la app y recibe el email de verificación (backend).
- [ ] Un usuario dispara la recuperación de contraseña desde la app y el email le llega.
- [ ] Ningún mensaje de error revela si un email existe o no en la plataforma.
