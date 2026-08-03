# Spec: Auth y sesión

> Leer `project.md` primero — ahí está el contrato exacto del backend (RSA, nonce, Basic Auth de
> cliente). Esta spec define cómo se comporta la app alrededor de ese contrato.

## Comportamiento esperado

### Login

- Pantalla de login pide email + password en texto plano (el cifrado pasa dentro de la app, nunca
  se manda plano por red).
- Flujo: `POST /auth/nonce` (Basic Auth de cliente) → cifrar `{password, nonce}` con RSA-OAEP →
  `POST /auth/login` (Basic Auth de cliente) con `{email, encryptedPassword}`.
- Éxito: recibe `accessToken` + `refreshToken`, se guardan en almacenamiento seguro (ver
  `decisions.md`), navega a la pantalla principal según el modo por default (cliente).
- Error 401: mensaje "credenciales inválidas" — nunca distinguir entre "email no existe" y
  "password incorrecto" (mismo criterio de seguridad que ya aplica en `TekoApp-Web`).
- Error 5xx / sin conexión: nunca tratarlo como "credenciales inválidas" — mostrar un estado de
  "servicio no disponible, reintentá" distinto (mismo criterio que el bug ya documentado y
  corregido en `TekoApp-Web/core/auth/session.ts`: 401 y 5xx NUNCA se colapsan al mismo estado).

### Sesión activa

- Al abrir la app con tokens guardados: llamar `GET /auth/scope` para traer datos frescos
  (nombre, avatar, roles, permisos) — nunca decodificar el JWT localmente para esto.
- Si `GET /auth/scope` devuelve 401: los tokens están vencidos/inválidos, intentar
  `POST /auth/refresh-token` una vez; si también falla, ir a login.
- Si `GET /auth/scope` devuelve 5xx o hay error de red: mostrar estado de "sin conexión con el
  servidor", NUNCA redirigir a login (evita el mismo bug ya corregido en la web).

### Refresh automático

- Interceptor de `dio`: cualquier request que devuelva 401 (que no sea el propio login/refresh)
  dispara un refresh automático una sola vez y reintenta el request original. Si el refresh
  también falla, cierra sesión localmente y navega a login.

### Modo cliente / profesional / admin

- Un usuario puede tener perfil de cliente y de profesional simultáneamente (mismo `Users`, ver
  `project.md`). La app debe permitir cambiar de modo sin volver a loguear — replicar el patrón
  de `TekoApp-Web` (`mode-switcher`, basado en `permissions`/existencia de perfil profesional
  provista por `GET /auth/scope`).
- Modo admin solo visible si el usuario tiene permisos de staff (`dashboard:read` u otro permiso
  admin) — mismo criterio que `isStaffUser()` en `TekoApp-Web/core/auth/permissions.ts`.

### Mi perfil (autoedición)

- Pantalla de perfil propio: editar nombre/apellido/teléfono (`PUT /auth/me`) y avatar (`POST
  /uploads/avatar` → persistir `key` vía `PUT /auth/me { avatarKey }`, ver `project.md` para por
  qué nunca se guarda la `url` presignada).
- No requiere ningún permiso especial más allá de estar autenticado.

## Casos de error a cubrir explícitamente (no opcional)

- Login con credenciales inválidas.
- Login sin conexión.
- Sesión expirada mientras se usa la app (token vence en medio de una acción) → refresh
  transparente, el usuario no debería notar nada salvo un pequeño delay.
- Refresh token también vencido → logout forzado con mensaje claro ("tu sesión expiró, volvé a
  iniciar sesión"), nunca un error críptico.
- Subida de avatar fallida (archivo muy grande, tipo no soportado) → mensaje específico, no un
  error genérico.
