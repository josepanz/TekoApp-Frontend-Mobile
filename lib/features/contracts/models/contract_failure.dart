/// Errores de las operaciones de contratos — mismo criterio que `BudgetFailure` (409 modelado
/// aparte de un 4xx de validación genérico).
sealed class ContractFailure implements Exception {
  const ContractFailure();
}

/// 4xx (salvo 409) — ej. opción todavía no seleccionada, checkbox de aceptación faltante, no ser
/// parte del contrato.
class ContractValidationFailure extends ContractFailure {
  const ContractValidationFailure(this.backendMessage);

  final String? backendMessage;
}

/// 409 — firma duplicada o fuera de turno.
class ContractConflictFailure extends ContractFailure {
  const ContractConflictFailure();
}

/// 5xx o sin conexión.
class ContractServiceUnavailableFailure extends ContractFailure {
  const ContractServiceUnavailableFailure();
}
