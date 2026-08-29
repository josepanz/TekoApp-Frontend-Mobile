# Fase 0010 — Contratos generados desde el presupuesto aceptado

**Implementada 2026-08-28** — ver `openspec/decisions.md`, "Fase 0010", para las decisiones
tomadas al implementar (copy legal placeholder+TODO, `url_launcher` en vez de un visor de PDF
embebido, `GET /contracts` y `viewerRole` agregados al backend durante esta fase). Feature 9 del
backlog 2026-08-22 (`openspec/decisions.md`). Contrato de dominio:
`openspec/specs/service-contracts.md` (mobile), `TekoApp-Backend/openspec/specs/service-
contracts.md` (backend).

**Depende de `0009-multi-option-budgets.md`** — implementada.

## Antes de empezar

Leer `openspec/specs/service-contracts.md` y el spec de backend completo, en particular la sección
"Riesgos / límites explícitos" — el
mecanismo de firma NO es una firma digital calificada, y la copy de mobile debe reflejar eso con
precisión (ver más abajo).

## Objetivo

Generar un contrato a partir de la `BudgetOptions` seleccionada, y que cliente y profesional lo
acepten cada uno por su lado ("firmen") antes de que quede vigente.

## Alcance

**Incluye**: pantalla de vista previa/firma del contrato para ambos roles, descarga del PDF una vez
firmado por ambas partes, listado de contratos propios.

**No incluye**: edición del contenido del contrato desde mobile — el contenido es el snapshot que
arma el backend a partir del presupuesto aceptado, inmutable.

## Pantallas / flujos

`lib/features/contracts/`.

- `data/contracts_api.dart` — `POST /budget-options/:referenceId/generate-contract`,
  `GET /contracts/:referenceId`, `POST /contracts/:referenceId/sign`,
  `GET /contracts/:referenceId/pdf`.
- `widgets/contract_preview_screen.dart` — renderiza `contentSnapshot` (alcance del servicio,
  opción de presupuesto elegida, línea de materiales/mano de obra, precio total) en un formato
  legible (no un JSON crudo — mapear a widgets de texto estructurado).
  - Sección de firma: checkbox "Leí y acepto el contenido de este contrato" + campo de texto
    "Escribí tu nombre completo para confirmar" — deshabilitar el botón de confirmar hasta que
    ambos estén completos. **Copy explícito y honesto**: aclarar en la pantalla que esto es un
    registro de aceptación electrónica, no reemplazar con lenguaje que sugiera una firma digital
    certificada — coordinar el texto exacto con José antes de publicar (ver límite legal del spec
    de backend).
  - Estado visual claro de "Pendiente de tu firma" / "Pendiente de la firma de la otra parte" /
    "Firmado por ambos" (texto + ícono, nunca solo color).
- `widgets/my_contracts_screen.dart` — listado de contratos propios (cliente y profesional ven los
  suyos), con acceso a descarga del PDF cuando `status = SIGNED`.

## Tareas

- [x] `data/`+`providers/`+`models/` de `contracts`.
- [x] Pantalla de vista previa + firma (ambos roles, mismo widget parametrizado por rol vía
      `Contract.isPendingViewerSignature`).
- [x] Descarga/visualización del PDF firmado — `url_launcher` (ya dependencia del proyecto, mismo
      patrón que `professional_documents_section.dart`), sin agregar un visor de PDF embebido
      nuevo (ver `openspec/decisions.md`).
- [x] Listado de contratos propios (`MyContractsScreen`, `GET /contracts` — endpoint agregado al
      backend durante esta fase, ver `openspec/decisions.md`).
- [x] Traducir a es/en, con especial cuidado en la copy legal (placeholder + `TODO(legal)` en la
      metadata de `es.arb`).
- [x] Tests: 16 nuevos (repositorio, providers de generar/firmar con 409, widget de firma con
      estados pendiente/parcial/completo, listado propio) + `budget_comparison_screen_test.dart`
      actualizado para la navegación nueva.

## Checkpoint de salida

- [x] Flujo completo cubierto por tests unitarios/mocks: seleccionar presupuesto (Fase 0009) →
      generar contrato → cliente firma → profesional firma → PDF disponible para ambos. Sin
      verificación manual contra el backend real corriendo con datos reales.
- [x] Intentar firmar dos veces o fuera de turno muestra el mensaje de error del backend (409 →
      `contractConflictError`), no uno genérico.
- [ ] Revisar con José el copy final de la pantalla de firma antes de publicar — el texto actual
      (`contractDisclaimerText`) es un placeholder genérico marcado `TODO(legal)`, confirmado con
      José que se resuelve más adelante con especialistas, no bloqueante para cerrar esta fase.

## Relación con otras features

Depende de `0009`. Su `legalTermsVersionId` conecta con `0012-data-and-image-consent.md`
(catálogo de versiones legales) — el contrato debe mostrar/enlazar qué versión de términos aplica.
