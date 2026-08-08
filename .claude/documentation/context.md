# Contexto actual — TekoApp-Frontend-Mobile

> Leer esto + la última sesión de `.claude/memory/sessions/` al empezar cualquier sesión nueva
> (ver `.claude/memory/memory.md`). Este archivo es un snapshot de alto nivel — el detalle vivo
> vive en `openspec/` (que SÍ hay que mantener actualizado a medida que se avanza, este archivo
> es secundario a eso).

## Estado (2026-08-02)

- **No hay código Flutter todavía.** Este repo tiene: `README.md` (contexto de producto),
  `openspec/` (SDD completo: contexto heredado, decisiones, specs por capacidad, plan de 6 fases),
  y este ecosistema `.claude/` (reglas, agentes, memoria) — todo preparado para que la próxima
  sesión arranque directo a codear la Fase 0001 sin tener que re-derivar nada.
- El backend (`TekoApp-Backend`) y el frontend web (`TekoApp-Web`) ya están construidos y
  endurecidos — este repo es el tercer cliente del mismo backend, heredando decisiones ya probadas
  (contrato de auth, convención `referenceId`, manejo de `avatarKey`/`avatarUrl`, etc.).
- **Push notifications: el backend ya implementó SSE + Web Push (VAPID) + FCM de verdad**
  (2026-08-02) — antes era solo una decisión documentada, ahora `POST/DELETE /notifications/fcm-tokens`
  existe y `NotificationsProcessor` envía FCM real. Ver `openspec/decisions.md` y
  `openspec/changes/0005-realtime-and-push.md`, ya actualizados para reflejar esto. Lo que falta
  para mobile no es infraestructura backend, es: proyecto Firebase real (credenciales) + el propio
  código Flutter.

## Próximo paso concreto

**Fase 0001 (bootstrap) cerrada (2026-08-07)** — estructura de `lib/`, Riverpod, go_router (con el
mecanismo de redirect ya probado, `test/app_redirect_test.dart`), smoke test de red real contra
`GET /countries` (`core/api_client/network_smoke_check_provider.dart`), testing/linter decididos y
CI en verde. Ver `openspec/changes/0001-project-bootstrap.md` para el detalle de qué quedó
pendiente de verificación manual (correr en un emulador/simulador real — no verificable desde una
sesión sin dispositivo).

**Fase 0002 (auth) en curso** — hecho hasta ahora, paso a paso vía TDD:

- Backend: nuevo endpoint público-para-cliente `GET /auth/public-key` (josepanz/TekoApp-Backend#23)
  — mobile no tiene BFF para guardar `BACKEND_JWT_PUBLIC_KEY` server-side como sí hace `TekoApp-Web`.
- `core/auth/rsa_encryptor.dart` — OAEP-SHA256 (`pointycastle`), compatibilidad cruzada con Node
  verificada empíricamente (no solo por lectura de RFCs, ver `openspec/decisions.md`).
- `core/auth/secure_cookie_storage.dart`/`cookie_jar_provider.dart` — el `refreshToken` viaja
  **solo como cookie httpOnly** (nunca en el body), persistida vía `flutter_secure_storage`.
- `features/auth/data/auth_repository.dart` — `login()`/`fetchScope()` reales, con los 3 estados
  de error del checklist (credenciales inválidas / sin conexión / servidor no disponible).
- `core/auth/bearer_auth_interceptor.dart` + `refresh_token_interceptor.dart` — Bearer automático
  + refresh transparente en 401 (nunca en los propios endpoints pre-login).
- `core/auth/session_provider.dart` — `sessionProvider` real (antes placeholder
  siempre-sin-sesión): `SessionUnknown` → `SessionAuthenticated`/`SessionUnauthenticated`/
  `SessionServiceUnavailable` (5xx/sin red NUNCA implica "sin sesión", ver
  `specs/auth-and-session.md`).

**Sigue**: pantalla de login real (3 estados de error visibles) + logout + reemplazar el guard
dummy de `go_router` (Fase 0001) por uno basado en `sessionProvider` de verdad — ver
`openspec/changes/0002-auth-and-design-system.md`.

## Qué NO hacer

- No asumir que un patrón de `TekoApp-Web` aplica 1:1 sin pasar por `openspec/project.md` primero
  (sección "Qué NO replicar del BFF") — mobile no tiene servidor intermedio.
- No implementar recepción de FCM sin haber confirmado, contra el backend real corriendo
  localmente, que los endpoints de `openspec/specs/notifications-push.md` siguen vigentes tal
  cual están documentados — la documentación puede desactualizarse entre sesiones.
