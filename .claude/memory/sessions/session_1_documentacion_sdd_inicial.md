# Sesión 1 — 2026-08-02 — Documentación SDD inicial (OpenSpec)

## Qué se hizo

- Reescrito `README.md` (antes genérico/desactualizado, listaba stack incorrecto) con el
  ecosistema real de repos, stack decidido (Flutter/Riverpod/go_router/dio), y pointers a
  `openspec/`.
- Creado `openspec/README.md`, `openspec/project.md` (contexto heredado completo de
  backend/web: contrato de auth, convención `referenceId`, `avatarKey`/`avatarUrl`, bugs a evitar,
  qué NO replicar del BFF web) y `openspec/decisions.md` (ADR-style: Flutter/Riverpod/go_router/dio
  decididos, FCM bloqueado por el backend en ese momento, storage seguro/testing/CI sin decidir).
- Creadas 8 specs de capacidad en `openspec/specs/` (auth-and-session, api-client, design-system,
  i18n, services-marketplace, payments, notifications-push, realtime-location).
- Creados 6 archivos de fase en `openspec/changes/` (0001 bootstrap → 0006 i18n-and-polish), cada
  uno con "Antes de empezar" + tareas + checkpoint de salida verificable.

## Estado al cierre

- Sin código Flutter todavía — repo 100% documentación, commiteado directo a `master` (este repo
  no tenía guardrail de rama en ese momento).

## Pendiente para la próxima sesión

- Ver sesión 2 — se retomó en la misma continuación de trabajo para agregar el ecosistema
  `.claude/` completo y reflejar el desbloqueo de FCM del lado backend.
