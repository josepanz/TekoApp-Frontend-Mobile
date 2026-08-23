# Fase 0009 — Presupuestos multi-opción generados desde la app

Spec de diseño, NO implementada todavía — feature 8 del backlog 2026-08-22
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

- [ ] `data/`+`providers/`+`models/` de `budgets` y `material_catalog`.
- [ ] Pantalla de armado de presupuesto (profesional) con cálculo en vivo de subtotales.
- [ ] Pantalla de comparación (cliente) con selección.
- [ ] Manejo de 409 en la selección (competidoras ya resueltas, propuesta ya no disponible).
- [ ] Traducir a es/en.
- [ ] Tests: provider de armado (validación de máximo de opciones), provider de selección (409),
      widget test de ambas pantallas incluyendo estado vacío (sin catálogo cargado para la
      categoría todavía).

## Checkpoint de salida

- [ ] Un profesional arma 2 opciones de presupuesto con materiales del catálogo real y las envía.
- [ ] El cliente las compara y selecciona una; la propuesta pasa a aceptada y las demás propuestas
      competidoras del mismo `Service` quedan auto-rechazadas (verificar contra el backend real,
      no solo la UI).
- [ ] El total mostrado en la comparación coincide exactamente con el que devuelve el backend
      (nunca un cálculo distinto hecho en mobile).

## Relación con otras features

`0010-contracts-from-accepted-budget.md` depende directamente de esta — el contrato se genera con
el contenido de la opción seleccionada acá.
