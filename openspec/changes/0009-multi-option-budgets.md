# Fase 0009 — Presupuestos multi-opción generados desde la app

**Implementada 2026-08-28** — ver "Tareas" abajo para el detalle. Spec original: feature 8 del
backlog 2026-08-22
(`openspec/decisions.md`). Contrato de dominio: `openspec/specs/multi-option-quotes.md` (mobile),
`TekoApp-Backend/openspec/specs/multi-option-quotes.md` (backend).
Web (catálogo de materiales): `TekoApp-Frontend-Web/openspec/specs/material-catalog.md`.

## Antes de empezar

Leer `openspec/specs/multi-option-quotes.md` y el spec de backend completo — el modelo de
`BudgetOptions`/`BudgetLineItems`/
`MaterialCatalog` y la lógica de selección (que reutiliza el auto-rechazo de `ServiceRequests`
competidoras ya implementado, ver `openspec/decisions.md` — "Aceptación de servicio").

## Objetivo

Reemplazar el precio único de una propuesta (`ServiceRequests.proposedPrice`) por hasta N opciones
de presupuesto alternativas que el profesional arma y el cliente compara y elige.

## Alcance

**Incluye**: pantalla de armado de presupuesto (profesional, dentro del flujo de "proponerse" a un
`Service`), pantalla de comparación (cliente, dentro del listado de propuestas recibidas),
selección de una opción (dispara la misma aceptación transaccional ya existente).

**No incluye**: negociación/contraoferta sobre una opción ya enviada.

## Pantallas / flujos

`lib/features/budgets/` (nuevo dominio).

### Profesional

- `data/budgets_api.dart` — `GET /material-catalog`, `PUT .../budget-options`.
- `widgets/budget_builder_screen.dart` — reemplaza (o extiende) el paso de "proponerse" existente
  en `lib/features/services/widgets/` (revisar el flujo real de la Fase 0003 antes de decidir si es
  una pantalla nueva o una extensión):
  - Lista de hasta `category.maxBudgetOptionsPerRequest` tarjetas de opción, cada una editable:
    `label` (texto libre con sugerencias "Económica"/"Estándar"/"Premium"), `description`, lista de
    `BudgetLineItems` (agregar desde `MaterialCatalog` filtrado por categoría+país, o "ítem libre"
    con descripción/cantidad/precio unitario manual), `estimatedHours`.
  - `totalPrice` se muestra calculado en vivo client-side para UX, pero el envío al backend nunca
    manda ese total como verdad — el backend lo recalcula server-side (mismo criterio ya aplicado a
    promociones en la Fase 0004: nunca confiar en un cálculo de descuento/monto hecho client-side).

### Cliente

- `widgets/budget_comparison_screen.dart` — tarjetas lado a lado (o carrusel en pantallas chicas)
  por cada `BudgetOptions` de una propuesta: precio, calidad de materiales (`qualityTier` por línea
  o resumen), horas estimadas, detalle expandible de line items.
  - Botón "Elegir esta opción" → `PATCH .../select` → mismo manejo de 409 ya usado para aceptación
    de servicios (competidoras auto-rechazadas server-side, la UI solo refleja el resultado).

## Tareas

- [x] `data/`+`providers/`+`models/` de `budgets` (`lib/features/budgets/`) — sin `models/` propio
      de `material_catalog` como dominio separado: `MaterialCatalogItem` vive dentro de
      `features/budgets/models/` porque en mobile solo se lee (nunca se administra), a diferencia
      de Web que sí tiene su propio dominio admin.
- [x] Pantalla de armado de presupuesto (profesional) — `BudgetBuilderScreen`, extiende (no
      reemplaza) el paso de "proponerse" existente: `ProposeOnServiceController.submit()` ahora
      devuelve la `ServiceRequest` creada, y `AvailableServicesScreen` navega directo a esta
      pantalla al tener éxito (ya no manda `proposedPrice`, el precio surge de las opciones).
      Cálculo de subtotal/total en vivo client-side solo para UX — el backend siempre recalcula al
      enviar.
- [x] Pantalla de comparación (cliente) — `BudgetComparisonScreen`, reemplaza el botón directo
      "Aceptar" de `_ServiceRequestsSection` (`service_detail_screen.dart`) por "Ver presupuestos".
- [x] Manejo de 409 en la selección (`BudgetConflictFailure`) — mismo criterio que
      `RespondToRequestController`.
- [x] Traducido a es/en (`l10n/{es,en}.arb`).
- [x] Tests: 12 tests nuevos en `test/features/budgets/` (repositorio: 6, provider de armado: 2,
      provider de selección: 2, widget de armado: 2, widget de comparación: 2) + actualización de
      2 tests existentes que cubrían el flujo viejo (`available_services_screen_test.dart`,
      `service_detail_screen_test.dart`) para reflejar la navegación nueva.
- [x] `flutter analyze` (0 issues) + `flutter test` (345/345) en verde.

## Decisiones tomadas al implementar (no en la spec original)

- `RespondToRequestController`/`respondToRequestControllerProvider` (aceptar una `ServiceRequests`
  directo, sin opciones) queda en el repo SIN llamador — no se borró: la capacidad de
  aceptar/rechazar sigue siendo válida a nivel de backend/repositorio, borrarla es una decisión de
  producto (¿se puede rechazar una propuesta explícitamente?) que no se pidió acá. Si en el futuro
  se confirma que no hace falta, es candidato a limpieza.
- `TekoInput` (shared widget) ganó un parámetro opcional `onChanged` — no lo tenía, hacía falta
  para capturar los campos editables del armado de presupuesto (label, descripción, cantidad,
  precio unitario). No rompe ningún uso existente (parámetro opcional).
- Sin límite client-side de `maxBudgetOptionsPerRequest` — el backend no expone ese número anidado
  en `Service.category` (`ServiceCategorySummary` no lo trae), así que el límite se comunica vía el
  mensaje de error 400 real del backend al enviar, no con una validación adivinada en la UI.

## Checkpoint de salida

- [ ] Un profesional arma 2 opciones de presupuesto con materiales del catálogo real y las envía —
      cubierto por tests unitarios/mocks, sin verificación manual contra el backend real corriendo.
- [ ] El cliente las compara y selecciona una; la propuesta pasa a aceptada y las demás propuestas
      competidoras del mismo `Service` quedan auto-rechazadas — mismo pendiente que arriba.
- [ ] El total mostrado en la comparación coincide exactamente con el que devuelve el backend —
      cubierto por diseño (la UI nunca calcula el total mostrado, siempre lee `totalPrice` de la
      respuesta), pero sin checkpoint real end-to-end con los 3 repos corriendo juntos — a cargo de
      José, mismo criterio que los checkpoints de negocio de fases anteriores.

## Relación con otras features

`0010-contracts-from-accepted-budget.md` depende directamente de esta — el contrato se genera con
el contenido de la opción seleccionada acá.
