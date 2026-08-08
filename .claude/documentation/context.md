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

- `LoginScreen` real (formulario + 3 estados de error visibles) + `LoginController`, navega a `/`
  al loguear.
- Guard real de `go_router`: `SessionAuthenticated` pasa, `SessionServiceUnavailable` nunca
  redirige a login (ver `specs/auth-and-session.md`), el resto sí. `refreshListenable` conecta
  `sessionProvider` al router para que el logout dispare el redirect solo, sin navegación
  imperativa — ver `app.dart`.
- Logout real en `ProfileScreen` (`AuthRepository.clearSession()` limpia `accessToken` + la cookie
  `refreshToken`).
- Sistema de diseño completo: `lib/design_system/tokens.generated.dart` (paleta real, portada de
  `tokens.json` vía un script Node de un solo uso — OKLCH→sRGB, no automatizado en `build.mjs`
  todavía), `ThemeData` claro/oscuro real, Poppins vía `google_fonts`, widgets base compartidos
  (`TekoButton`/`TekoCard`/`TekoAvatar`/`TekoBadge`/`TekoInput`).
- "Mi perfil" real: ver/editar nombre/apellido/teléfono + avatar (`ProfileRepository`,
  `UpdateProfileController`/`UploadAvatarController`).
- Test e2e (`test/e2e/login_profile_logout_test.dart`): login → home → Mi perfil → logout, de
  punta a punta contra el código real (solo mockea la red) — corre como test de widgets, no
  `integration_test/`, porque este entorno no tiene emulador/dispositivo (ver
  `.claude/rules/test.md`).

**Fase 0002 (checklist de código) completa.** Quedó pendiente únicamente lo que requiere un
dispositivo/backend real y no es código: el checkpoint de salida (login contra el backend local
con una cuenta de seed, persistencia entre reinicios, refresh de un token vencido de verdad,
comparación visual con `TekoApp-Web`, subida de avatar de punta a punta) — tarea de José.

**Fase 0003 (marketplace de servicios, checklist de código) completa (2026-08-08)** — 9 PRs
(#41-#49): catálogo de categorías/tipos, modelos+repositorio de `Service`/`ServiceRequest` con
manejo explícito de 409, pedir servicio (con ubicación vía `geolocator`), mis servicios
(listado+detalle), selector de modo cliente/profesional + gate + onboarding de perfil profesional,
servicios disponibles + proponerse, ver propuestas competidoras y aceptar una, marcar en progreso/
completado. Divergencias deliberadas documentadas en `openspec/decisions.md` y en el propio
`changes/0003-services-marketplace-core.md` (modelo de `ServiceRequests` en vez del atajo que usa
`TekoApp-Web`, Pasos 5+6 del plan fusionados en un solo PR, proponerse de un solo toque sin
capturar precio/horas todavía). Checkpoint de salida (dos usuarios reales, DB real, conflicto 409
real) pendiente — tarea de José, mismo criterio que fases anteriores.

**Fase 0004 (pagos y calificaciones, checklist de código) completa (2026-08-08)** — 7 PRs
(#51-#57): decisiones + grafo de conocimiento, métodos de pago (modelo/repo/pantalla), promociones
(validate/apply), pagar un servicio completado (monto server-side, promoción opcional), historial
de pagos + reembolso parcial/total, calificación bidireccional. Antes de este paso se auditó y
corrigió `TekoApp-Backend` (PRs #24-#27: bug real de `professionalId` en pagos, 2 condiciones de
carrera en métodos de pago, endpoint faltante `GET /payments/methods`, y un bug que bloqueaba dos
reembolsos parciales consecutivos sobre el mismo pago — el propio checkpoint de esta fase lo exige
explícitamente). Divergencia documentada en `openspec/decisions.md`: se simplificó el manejo de
`ALREADY_EXISTS_FOR_SERVICE` a mostrar el mensaje del backend tal cual, sin el redirect especial a
historial que el plan original proponía (evita matching frágil contra texto traducible). Checkpoint
de salida (pago real con promoción real, dos reembolsos parciales reales, calificar y confirmar que
no se puede de nuevo) pendiente — tarea de José, mismo criterio que fases anteriores.

**Próximo paso**: Fase 0005 (`openspec/changes/0005-realtime-and-push.md`) o la que José decida
priorizar.

## Qué NO hacer

- No asumir que un patrón de `TekoApp-Web` aplica 1:1 sin pasar por `openspec/project.md` primero
  (sección "Qué NO replicar del BFF") — mobile no tiene servidor intermedio.
- No implementar recepción de FCM sin haber confirmado, contra el backend real corriendo
  localmente, que los endpoints de `openspec/specs/notifications-push.md` siguen vigentes tal
  cual están documentados — la documentación puede desactualizarse entre sesiones.
