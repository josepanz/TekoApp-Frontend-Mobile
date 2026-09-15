# Fase 0016 — CTA de reclutamiento y portafolio de trabajos

Spec de diseño, NO implementada todavía. Contrato completo:
`openspec/specs/professional-onboarding-and-portfolio.md`.

## Antes de empezar

Leer `openspec/specs/professional-onboarding-and-portfolio.md` completo, en particular "Estado
real relevado" — la mayor parte del pedido de José (onboarding, mode-switch) YA está resuelta en
este repo. Solo faltan 2 cosas reales: el CTA de reclutamiento en el home (Fase 3, sin
dependencias) y la galería de portafolio (Fase 5, bloqueada por
`TekoApp-Backend/openspec/changes/0012-professional-onboarding-and-portfolio.md`).

## Objetivo

Hacer descubrible el flujo de "convertirse en profesional" que ya existe, y reemplazar la subida
de portafolio como documento único por una galería real.

## Tareas

- [ ] **Fase 3**: card de reclutamiento en `home_screen.dart`.
- [ ] **Fase 5** (bloqueada por Backend): `lib/features/professional_portfolio/` completo.
- [ ] `flutter analyze`, `flutter test` en 0 issues en cada fase.

## Checkpoint de salida

Ver "Checkpoint de salida (Mobile)" en `openspec/specs/professional-onboarding-and-portfolio.md`.
