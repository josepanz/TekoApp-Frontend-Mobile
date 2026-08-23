# Fase 0006 — Completar i18n, admin (si aplica) y pulido final

## Antes de empezar

Leer: `specs/i18n.md`.

## Objetivo

Cerrar cualquier deuda de traducción/pulido acumulada durante las fases anteriores (si se siguió
la recomendación de traducir sobre la marcha, esta fase debería ser corta), y decidir si el modo
admin tiene sentido en mobile o queda exclusivo de `TekoApp-Web`.

## Tareas

- [x] Auditoría de strings sin traducir (buscar cualquier texto hardcodeado que se haya colado en
      las fases anteriores). — limpia, ver `decisions.md`.
- [x] Selector de idioma explícito en la app (no solo negociación automática por sistema
      operativo) — decidir dónde vive en la navegación (ej. junto a "Mi perfil", igual que en
      `TekoApp-Web`).
- [x] Decisión de producto (no técnica): ¿el modo admin/backoffice tiene sentido en mobile, o
      queda exclusivo de `TekoApp-Web`? — decidido: NO en mobile, ver `decisions.md`.
- [x] Accesibilidad: pasar el mismo checklist de `TekoApp-Web/.claude/rules/accessibility.md`
      adaptado a Flutter (contraste, targets táctiles ≥44px, estado nunca solo por color, labels
      accesibles en controles solo-ícono) sobre todas las pantallas construidas hasta acá. — 1
      hallazgo real corregido (estrellas de calificar sin label), ver `decisions.md`.
- [x] Revisar el offline-first vs. online-only pendiente de `decisions.md` — ya estaba confirmado
      con José (2026-08-08): online-only. Sin cambios.

## Checkpoint de salida (checkpoint final de todo el plan, no solo de esta fase)

- [ ] Cero strings hardcodeados detectados en una revisión completa del código.
- [ ] Cambiar el idioma de la app en runtime y confirmar que TODA la UI (incluyendo mensajes de
      error que vienen traducidos del backend vía header `x-lang`) responde al cambio.
- [ ] Checklist de accesibilidad completo, con hallazgos corregidos (no solo "revisado", sino
      "corregido lo que falló").
- [ ] Recorrido completo de los flujos de las Fases 2 a 5 una vez más, de punta a punta, sin
      encontrar ningún texto sin traducir ni ningún estado de error genérico donde debería haber
      uno específico.
