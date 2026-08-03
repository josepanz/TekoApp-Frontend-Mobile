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

Arrancar `openspec/changes/0001-project-bootstrap.md` — leer su sección "Antes de empezar", crear
`pubspec.yaml` + la estructura de `lib/` descrita en `.claude/CLAUDE.md`, y confirmar en
`openspec/decisions.md` las decisiones todavía abiertas que esa fase toque (framework de testing,
almacenamiento seguro de tokens si el bootstrap ya incluye un spike de auth).

## Qué NO hacer

- No asumir que un patrón de `TekoApp-Web` aplica 1:1 sin pasar por `openspec/project.md` primero
  (sección "Qué NO replicar del BFF") — mobile no tiene servidor intermedio.
- No implementar recepción de FCM sin haber confirmado, contra el backend real corriendo
  localmente, que los endpoints de `openspec/specs/notifications-push.md` siguen vigentes tal
  cual están documentados — la documentación puede desactualizarse entre sesiones.
