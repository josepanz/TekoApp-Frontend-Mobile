# Fase 0004 — Pagos y calificaciones

## Antes de empezar

Leer: `specs/payments.md`.

## Objetivo

Cerrar el ciclo económico del servicio: pagar un servicio completado y calificar a la contraparte.

## Tareas

- [ ] Gestión de métodos de pago propios (agregar/eliminar/marcar default) — respetar la regla de
      "no se puede eliminar el único método activo".
- [ ] Pantalla de pago de un servicio completado: elegir método, confirmar monto (calculado
      server-side), procesar.
- [ ] Aplicar código de promoción antes de pagar (validación server-side, nunca calcular el
      descuento final client-side).
- [ ] Historial de pagos propios (como cliente y como profesional) con detalle de transacciones.
- [ ] Flujo de reembolso (solo sobre pagos COMPLETED, mostrando el monto disponible real para
      reembolsar, no asumiendo que siempre es el total).
- [ ] Calificación bidireccional al completar un servicio: cliente califica profesional y
      viceversa — ocultar la opción si ya se calificó (el backend rechaza el duplicado, pero la UI
      no debería ni ofrecerlo).
- [ ] Traducir a es/en todo texto nuevo de esta fase.

## Checkpoint de salida

- [ ] Pago de un servicio completado de punta a punta contra el backend real, incluyendo la
      aplicación de un código de promoción válido.
- [ ] Intentar eliminar el único método de pago → la UI muestra el mismo mensaje que el backend
      devuelve, no un genérico.
- [ ] Reembolso parcial seguido de un segundo reembolso parcial sobre el mismo pago → el monto
      disponible se actualiza correctamente entre uno y otro.
- [ ] Calificar un servicio y confirmar que la opción de calificar de nuevo ya no aparece.
