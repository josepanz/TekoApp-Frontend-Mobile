# Fase 0011 — Disclosure de contenido generado por IA

Spec de diseño, NO implementada todavía — feature 10 del backlog 2026-08-22
(`openspec/decisions.md`). Contrato de dominio: `openspec/specs/ai-content-disclosure.md` (mobile),
`TekoApp-Backend/openspec/specs/ai-content-disclosure.md` (backend).
Web (auditoría): `TekoApp-Frontend-Web/openspec/specs/ai-content-disclosure-admin.md`.

## Antes de empezar

Leer `openspec/specs/ai-content-disclosure.md` completo. Importante: esta fase NO agrega ninguna
generación de IA real a la app — solo el mecanismo de auto-declaración y el badge de lectura.

## Objetivo

Agregar el checkbox de auto-declaración en los puntos de creación de contenido elegibles, y un
badge compartido para mostrar cualquier disclosure existente.

## Alcance

**Incluye**: `lib/features/ai_disclosures/` (dominio nuevo, mismo patrón `data/providers/models`),
`shared/widgets/ai_disclosure_badge.dart` (widget compartido).

**No incluye**: ninguna feature de generación de contenido con IA.

## Pantallas / flujos

- `data/ai_disclosures_api.dart` — `PUT`/`DELETE`/`GET` de `/ai-disclosures`.
- `providers/ai_disclosure_provider.dart` — `FutureProvider.family` por `(entityType,
  entityReferenceId)` para lectura, `AsyncNotifier` de mutación para declarar/retirar.
- Checkbox "Usé IA para esto" agregado a los formularios de creación de contenido elegibles según
  `APP_CONFIG.aiDisclosure.userDeclarableTypes` del backend (consultar antes de hardcodear la
  lista — puede cambiar sin deploy).
- `shared/widgets/ai_disclosure_badge.dart` — badge reusado en cualquier pantalla que muestre
  contenido con disclosure activo (texto + ícono, no solo color).

## Tareas

- [x] `data/`+`providers/`+`models/` de `ai_disclosures`.
- [x] Widget compartido `AiDisclosureBadge`.
- [x] Checkbox de auto-declaración en los formularios de contenido elegibles ya existentes al
      momento de implementar esta fase (revisar cuáles existen realmente entonces, no asumir la
      lista de hoy) — confirmados 2: `request_service_screen.dart`/`professional_onboarding_screen.dart`.
- [x] Traducir a es/en.
- [x] Tests: provider (declarar propio ok, declarar de otro → 403), widget test del badge en sus
      distintos estados (con/sin disclosure).

## Checkpoint de salida

- [x] Un usuario declara su propio contenido como asistido por IA y el badge aparece donde
      corresponde, para cualquier viewer (no solo para el declarante) — wired en `service_detail_screen.dart`.
- [x] Intentar declarar contenido ajeno falla con el mensaje correcto, no uno genérico —
      `AiDisclosureForbiddenFailure`/`AiDisclosureValidationFailure` distintos, backendMessage passthrough.
