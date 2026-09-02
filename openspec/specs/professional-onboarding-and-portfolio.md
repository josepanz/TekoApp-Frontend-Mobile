# Spec: Onboarding de profesional y portafolio de trabajos (Mobile)

Backend: `TekoApp-Backend/openspec/specs/professional-onboarding-and-portfolio.md`.
Web: `TekoApp-Frontend-Web/openspec/specs/professional-onboarding-and-portfolio.md`.
Reportado por José 2026-09-01 sobre el portal Web — al relevar el mismo pedido en Mobile se
confirmó que la mayor parte YA está resuelta acá (a diferencia de Web). Esta spec cubre solo el
gap real: el home no invita a nadie a postularse, y el portafolio de trabajos previos no es una
galería real todavía.

## Estado real relevado (2026-09-01)

- `ProfessionalOnboardingScreen`
  (`lib/features/professional_profile/widgets/professional_onboarding_screen.dart`, ruta
  `/profesional/onboarding`) YA existe y funciona: categoría, descripción, tarifas, años de
  experiencia, skills → `POST /professionals`. **No necesita cambios.**
- El mode-switch cliente↔profesional YA existe y funciona (`lib/core/mode/app_mode_provider.dart`
  + botones en `HomeScreen`/`ProfessionalHomeScreen`), con el gate de ruta correcto
  (`lib/app.dart`, redirige a onboarding si no hay perfil todavía). **No necesita cambios.**
- La subida de documentos de compliance (`lib/features/professional_documents/`) YA existe y
  funciona, incluida la categoría `portfolio` — pero implementada como un documento único más
  (mismo flujo que antecedentes/certificaciones), no como una galería de múltiples fotos. Este es
  el mismo gap que en Backend/Web: hace falta un modelo dedicado.
- `HomeScreen` (cliente) no tiene ningún texto de reclutamiento — solo un ícono pequeño en el
  AppBar (`home_professional_mode_button`, tooltip "Modo profesional") que ya asume que el usuario
  sabe que existe esa opción. Nada equivalente a "¿Querés trabajar con nosotros?".

## Objetivo

1. Agregar un CTA real de reclutamiento en el home de cliente (Fase 3) — la única pieza de UI que
   falta para que el flujo YA existente (`/profesional/onboarding`) sea descubrible.
2. Reemplazar la subida de "portafolio" como documento único por una galería real de múltiples
   fotos (Fase 5, depende de `TekoApp-Backend`
   `openspec/changes/0012-professional-onboarding-and-portfolio.md`, Fase 4).

## Fuera de alcance

- Tocar `ProfessionalOnboardingScreen`, el mode-switch, o el flujo de documentos de compliance —
  todo eso ya funciona y no es parte de esta spec.

## Fase 3 — CTA de reclutamiento en el home

- [ ] `lib/features/home/widgets/home_screen.dart` — agregar una card visible solo si
      `myProfessionalProfileProvider` no tiene datos (mismo gate que ya usa el botón del AppBar),
      con copy real ("¿Querés trabajar con nosotros? Postulate como profesional") y navegación a
      `/profesional/onboarding` (ya existe, no hay que crear ruta nueva).
- [ ] Claves nuevas en `es.arb`/`en.arb` (`homeRecruitProfessionalTitle`/`...Cta`, etc.),
      `flutter gen-l10n`.
- [ ] Test: la card no aparece si el usuario ya tiene perfil profesional.
- [ ] `flutter analyze`, `flutter test` en 0 issues.

## Fase 5 — Galería de portafolio (depende de Backend Fase 4)

**No arrancar hasta que el contrato de `GET/POST/PATCH/DELETE /professionals/me/portfolio` de
`TekoApp-Backend` esté confirmado e implementado.**

- [ ] Nuevo `lib/features/professional_portfolio/` (`data/`, `providers/`, `models/`, `widgets/`)
      — espejo de `professional_documents/` pero para el modelo nuevo.
- [ ] `PortfolioUploadSheet` — subir foto (cámara o galería, `image_picker`, mismo patrón que
      `UploadDocumentSheet`) + caption opcional.
- [ ] `PortfolioGalleryWidget` — grilla de fotos con reordenar/ocultar/borrar, embebida en la
      pantalla de perfil profesional (confirmar el nombre real del archivo al implementar).
- [ ] Mostrar el portafolio visible en la vista pública del profesional que el cliente ve al
      elegirlo (confirmar contra el código real qué pantalla es, antes de asumir el nombre).
- [ ] Retirar `portfolio` de las categorías seleccionables en el flujo genérico de
      `professional_documents` una vez la galería nueva esté disponible (evitar que quede
      duplicado — coordinar con la deprecación de `DocumentCategory.PORTFOLIO` del lado backend).
- [ ] Tests (provider, widget) + `flutter analyze`/`flutter test` en 0 issues.

## Checkpoint de salida (Mobile)

- [ ] Un cliente ve el CTA de reclutamiento en el home si todavía no es profesional, y no lo ve si
      ya lo es.
- [ ] Un profesional arma su portafolio (múltiples fotos) desde la app, tras Backend Fase 4.
