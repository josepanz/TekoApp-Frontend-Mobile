/// Errores de las operaciones de presupuestos multi-opción — mismo criterio que `ServiceFailure`
/// (409 modelado aparte de un 4xx de validación genérico).
sealed class BudgetFailure implements Exception {
  const BudgetFailure();
}

/// 4xx (salvo 409) — ej. máximo de opciones excedido, ítem de catálogo inexistente.
class BudgetValidationFailure extends BudgetFailure {
  const BudgetValidationFailure(this.backendMessage);

  final String? backendMessage;
}

/// 409 — el servicio ya no acepta propuestas (otra opción/profesional fue aceptado mientras tanto).
class BudgetConflictFailure extends BudgetFailure {
  const BudgetConflictFailure();
}

/// 5xx o sin conexión.
class BudgetServiceUnavailableFailure extends BudgetFailure {
  const BudgetServiceUnavailableFailure();
}
