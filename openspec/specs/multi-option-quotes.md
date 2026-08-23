# Spec: Presupuestos multi-opción generados desde la app

Backend: `TekoApp-Backend/openspec/specs/multi-option-quotes.md`. Web (catálogo de materiales):
`TekoApp-Frontend-Web/openspec/specs/material-catalog.md`. Plan de fase:
`openspec/changes/0009-multi-option-budgets.md`. Depende de `ServiceRequests` (ver
`openspec/specs/services-marketplace.md`).

## Modelo de dominio (ya definido en el backend, replicar el contrato tal cual)

- **MaterialCatalog**: catálogo parametrizable por categoría+país — `name`, `unit`, `qualityTier`
  (`BASIC`/`STANDARD`/`PREMIUM`), `defaultPrice` (sugerido, no fijo).
- **BudgetOptions**: una opción de presupuesto sobre una `ServiceRequests` — `label` (texto libre),
  `totalPrice`/`estimatedHours` (siempre recalculados server-side), `isSelected`.
- **BudgetLineItems**: ítems de línea de una opción — de catálogo (`catalogItemId`) o libres,
  `quantity`/`unitPrice`/`subtotal`.
- `Category.maxBudgetOptionsPerRequest`: cuántas opciones puede armar un profesional por
  propuesta (configurable por categoría).

## Flujos de UI esperados

### Profesional

1. Al proponerse a un `Service` `PENDING`: armar hasta `maxBudgetOptionsPerRequest` opciones,
   cada una con línea de materiales (del catálogo o libres) + mano de obra.

### Cliente

1. Comparar las opciones recibidas de una propuesta (tarjetas: precio, calidad, horas, detalle
   expandible) y elegir una.

## Reglas de negocio a respetar en la UI

- El total mostrado en la UI es solo un cálculo en vivo para UX — la fuente de verdad es siempre lo
  que devuelve el backend tras `PUT .../budget-options`, nunca lo que calculó el cliente (mismo
  criterio ya aplicado a promociones en la Fase 0004: nunca confiar en un cálculo de monto hecho
  client-side).
- Seleccionar una opción (`PATCH .../select`) reutiliza la misma lógica de auto-rechazo de
  `ServiceRequests` competidoras ya implementada — manejar el resultado igual que la aceptación de
  servicio existente (ver `openspec/specs/services-marketplace.md`), incluyendo el manejo de 409.

## Fuera de alcance de esta spec

Negociación/contraoferta sobre una opción ya enviada. El contrato generado a partir de la opción
elegida (ver `specs/service-contracts.md`).
