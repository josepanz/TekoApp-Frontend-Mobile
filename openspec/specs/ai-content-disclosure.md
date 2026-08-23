# Spec: Disclosure de contenido generado por IA

Backend: `TekoApp-Backend/openspec/specs/ai-content-disclosure.md`. Web (auditoría de staff):
`TekoApp-Frontend-Web/openspec/specs/ai-content-disclosure-admin.md`. Plan de fase:
`openspec/changes/0011-ai-content-disclosure.md`.

**Importante — esta spec NO introduce generación de IA real en mobile.** Hoy la app no tiene
ninguna feature que genere texto/imágenes/presupuestos con IA. Esto solo agrega el mecanismo de
auto-declaración para cuando un usuario quiera marcar su propio contenido como asistido por IA, y
el badge de lectura para mostrar cualquier disclosure existente (de plataforma o de usuario).

## Modelo de dominio (ya definido en el backend, replicar el contrato tal cual)

- **AiContentDisclosures**: `entityType` (`SERVICE_DESCRIPTION`/`BUDGET_OPTION`/`PROGRESS_NOTE`/
  `PROFESSIONAL_DESCRIPTION`/`IMAGE`/`OTHER`), `source` (`PLATFORM_AI`/`USER_DECLARED_AI`), `note`
  opcional.

## Flujos de UI esperados

1. En los puntos de creación de contenido elegibles (nota de bitácora, descripción de presupuesto,
   bio de profesional — la lista exacta la define `APP_CONFIG.aiDisclosure.userDeclarableTypes`
   del backend, consultar antes de hardcodear cuáles): checkbox opcional "Usé IA para esto" +
   campo de nota opcional.
2. En cualquier pantalla que muestre ese contenido: un badge/ícono compartido
   (`shared/widgets/ai_disclosure_badge.dart`) si existe un disclosure activo para esa entidad —
   mismo componente reusado en todos los puntos, no un badge distinto por feature.

## Reglas de negocio a respetar en la UI

- El checkbox de auto-declaración es siempre opcional y post-hoc (se marca al crear/editar el
  contenido, no bloquea el guardado).
- Solo el dueño del contenido puede declarar/retirar su propio disclosure (`403` si no).
- No inventar textos de disclosure por pantalla — usar las claves i18n centralizadas del backend
  (mismo catálogo es/en del resto de la app).

## Fuera de alcance de esta spec

Cualquier feature real de generación de IA en mobile.
