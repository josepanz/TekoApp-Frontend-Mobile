/// Errores de cualquier operación sobre pagos/métodos de pago — a diferencia de `ServiceFailure`,
/// las reglas de negocio de este dominio (`CANNOT_DELETE_ONLY_METHOD`, `REFUND_EXCEEDS_AVAILABLE`,
/// `ONLY_COMPLETED_CAN_BE_REFUNDED`, etc.) viajan como 400 `BadRequestException` en el backend, no
/// como 409 — y son mensajes específicos y ya en español, a diferencia de errores de validación de
/// campo genéricos. Por eso ambas variantes 4xx cargan el mensaje textual del backend
/// (`error.message` del envelope de error, ver `openspec/decisions.md`): la UI lo muestra tal
/// cual en vez de inventar uno propio, en los casos puntuales donde la tarea lo pide.
sealed class PaymentFailure implements Exception {
  const PaymentFailure();
}

/// 4xx (salvo 409) — incluye tanto validación de campos como reglas de negocio rechazadas
/// (ambas via `BadRequestException`/`NotFoundException` en el backend).
class PaymentValidationFailure extends PaymentFailure {
  const PaymentValidationFailure(this.backendMessage);

  final String? backendMessage;
}

/// 409 — conflicto real de estado (`updateMany` condicional, ver `openspec/project.md`).
class PaymentConflictFailure extends PaymentFailure {
  const PaymentConflictFailure(this.backendMessage);

  final String? backendMessage;
}

/// 400 con `errorCode: 'PAYMENT_METHOD_EXPIRED'` — el backend rechaza `POST /payments` cuando el
/// método elegido ya venció (`PaymentMethod.expiresAt` en el pasado al momento de confirmar), aun
/// si la UI lo mostraba habilitado cuando se pintó la pantalla (puede vencer entre que se carga el
/// selector y se confirma el pago). Se distingue de `PaymentValidationFailure` genérica para que
/// la UI pueda mostrar un mensaje específico en vez de uno genérico de validación — mismo criterio
/// que `LegalConsentsLegalHoldFailure` (`errorCode: 'LEGAL_HOLD_ACTIVE'`).
class PaymentMethodExpiredFailure extends PaymentFailure {
  const PaymentMethodExpiredFailure(this.backendMessage);

  final String? backendMessage;
}

/// 5xx o sin conexión.
class PaymentServiceUnavailableFailure extends PaymentFailure {
  const PaymentServiceUnavailableFailure();
}
