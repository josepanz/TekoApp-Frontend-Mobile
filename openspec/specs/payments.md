# Spec: Pagos

## Modelo de dominio

- **PaymentMethodEntity**: métodos de pago guardados del usuario (`type`: CASH/CREDIT_CARD/QR/
  WALLET/etc., `provider`: BANCARD/MERCADO_PAGO/STRIPE/etc., `isDefault`, `details` — forma
  específica por tipo, ej. últimos 4 dígitos + marca para tarjeta, alias para QR/wallet).
- **Payments**: el pago de un servicio completado — `amount`/`fee`/`tax`/`totalAmount`,
  `status` (PENDING/PROCESSING/COMPLETED/FAILED/REFUNDED/PARTIAL_REFUNDED/CANCELLED),
  `paymentMethod`/`paymentProvider`, `transactionId` único.
- **PaymentTransaction**: historial de movimientos de un pago (el pago original + eventuales
  reembolsos) — `type` (PAYMENT/REFUND/CHARGEBACK/ADJUSTMENT/FEE/TAX), `status`.

## Flujos de UI esperados

1. **Gestión de métodos de pago**: agregar/eliminar método de pago propio, marcar uno como
   default. No se puede eliminar el único método de pago activo (regla ya validada server-side,
   ver mensaje `payments.CANNOT_DELETE_ONLY_METHOD` en el catálogo i18n del backend — la UI
   debería mostrar ese mismo mensaje, no inventar uno propio).
2. **Pagar un servicio completado**: elegir método de pago guardado (o uno nuevo), confirmar monto
   (ya calculado server-side desde `finalAmount` del `Service`), procesar.
3. **Ver historial de pagos propios** (como cliente: pagos que hice; como profesional: pagos que
   recibí) con su estado y detalle de transacciones.
4. **Reembolso**: solo iniciable en pagos `COMPLETED` (regla server-side:
   `payments.ONLY_COMPLETED_CAN_BE_REFUNDED`), el monto de reembolso no puede exceder el disponible
   (`payments.REFUND_EXCEEDS_AVAILABLE` — el backend ya soporta reembolsos parciales acumulativos,
   la UI debe mostrar cuánto queda disponible para reembolsar, no asumir que siempre es el monto
   total).

## Reglas de negocio a respetar en la UI

- Un pago solo se puede cancelar mientras está PENDING (ver `payments.ONLY_PENDING_CAN_BE_UPDATED`
  / `payments.CANNOT_BE_CANCELLED` en el catálogo i18n del backend) — no ofrecer "cancelar" en un
  pago ya COMPLETED/FAILED.
- El backend protege reembolsos concurrentes con un lock a nivel de fila (ver `project.md` sobre
  condiciones de carrera) — un doble tap en "reembolsar" no debería duplicar el reembolso; además
  de deshabilitar el botón mientras la request está en curso (UX básica), confiar en que el
  backend rechaza el duplicado si igual llega dos veces.
- **Nunca mostrar ni loguear el número completo de una tarjeta ni datos sensibles de pago** —
  el backend ya devuelve solo datos enmascarados (`details` con últimos 4 dígitos), la app nunca
  debería recibir ni loguear el dato completo en ningún punto.

## Promociones

- **Promotion**: código de descuento (`PERCENTAGE`/`FIXED_AMOUNT`/`FREE_SERVICE`), con límites de
  uso total y por usuario, ventana de validez (`validFrom`/`validUntil`).
- Flujo: el usuario ingresa un código antes de pagar → validar contra el backend (existe, vigente,
  no excedió el límite de uso del usuario) → aplicar el descuento al monto antes de confirmar el
  pago. Nunca calcular el descuento client-side de forma definitiva — el backend recalcula y
  valida en el momento de aplicar (mismo criterio anti-condición-de-carrera que el resto de
  transiciones de estado).
