# Sesión 2 — 2026-08-02 — Ecosistema `.claude/` + desbloqueo de FCM

## Qué se hizo

- El backend (`TekoApp-Backend`) implementó de verdad SSE + Web Push (VAPID) + FCM (antes solo
  documentado como decisión/backlog) — ver
  `TekoApp-Backend/.claude/documentation/notifications-push-architecture.md`.
- Actualizado `openspec/decisions.md`, `openspec/changes/0005-realtime-and-push.md` y
  `openspec/specs/notifications-push.md` para reflejar que FCM ya NO está bloqueado por
  infraestructura backend — el bloqueo restante es solo: proyecto Firebase real (credenciales) +
  código Flutter, no arquitectura.
- Creado el ecosistema `.claude/` completo por primera vez en este repo:
  - `CLAUDE.md` — dominio, stack decidido, estructura de `lib/` planeada (Fase 0001), reglas
    críticas, links a rules/agents.
  - `rules/`: `flutter-architecture.md`, `test.md`, `datetime.md` (mismo bug de
    `America/Asuncion` que backend/web), `auth.md` (contrato + guardrail de rama nuevo),
    `design-system.md`, `i18n.md`.
  - `agents/`: `code-reviewer.md`, `testing-agent.md`, `tdd-refactor.md` (adaptados de los mismos
    3 agentes en `TekoApp-Backend`/`TekoApp-Web`, sintaxis Flutter/Dart/Riverpod).
  - `commands/commit.md` — Conventional Commits, sin referenciar `commitlint` todavía (no hay
    `pubspec.yaml`/pipeline propio).
  - `documentation/context.md` — snapshot de estado + próximo paso concreto.
  - `memory/memory.md` + `memory/sessions/` — protocolo de inicio/cierre de sesión, mismo formato
    que los otros 2 repos.
- **Guardrail de rama nuevo** (`.claude/rules/auth.md`): este repo no tenía protección de rama y
  tuvo commits directos a `master` en su historia (incluida la Sesión 1). A partir de esta sesión,
  todo trabajo nuevo va en rama + PR — se abrió `feature/backend-push-ready-and-claude-ecosystem`
  para este mismo commit, en vez de seguir el patrón anterior de push directo.

## Errores encontrados y su solución

- Ninguno de código (no hay código Flutter todavía) — el "error" evitado fue de proceso: sin este
  guardrail, este trabajo también hubiera ido directo a `master` sin PR, perdiendo la
  revisabilidad que sí tienen los otros 2 repos.

## Estado al cierre

- Sin código Flutter todavía (sin cambios respecto a la Sesión 1) — este ecosistema `.claude/`
  prepara la próxima sesión para arrancar directo a codear la Fase 0001.
- PR abierto contra `master` con esta rama — ver el link que dio la sesión que cerró esto (no se
  hardcodea acá para no desactualizarse).

## Pendiente para la próxima sesión

- Arrancar `openspec/changes/0001-project-bootstrap.md`: crear `pubspec.yaml` + estructura de
  `lib/` (ver `.claude/CLAUDE.md`), confirmar en `openspec/decisions.md` el framework de testing y
  el mecanismo de generación del tema Dart desde `tokens.json` antes de escribir el primer widget.
- Una vez exista `lib/`, correr `/graphify .` para generar el grafo de conocimiento del repo (no
  existe todavía, no había código que graficar).
