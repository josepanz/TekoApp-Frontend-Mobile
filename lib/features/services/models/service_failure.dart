/// Errores de cualquier operación de escritura sobre `Services`/`ServiceRequests` (crear, aceptar,
/// iniciar, completar, cancelar, proponerse, responder) — mismo criterio que `ProfileFailure`, con
/// el 409 de conflicto de estado (`updateMany` condicional, ver `openspec/project.md`) modelado
/// aparte: nunca mostrarlo como el mismo mensaje genérico que un 4xx de validación.
sealed class ServiceFailure implements Exception {
  const ServiceFailure();
}

/// 4xx (salvo 409) — datos rechazados por el backend (ej. `estimatedHours` fuera de rango).
class ServiceValidationFailure extends ServiceFailure {
  const ServiceValidationFailure();
}

/// 409 — la transición de estado ya no es válida porque algo cambió mientras tanto (otro
/// profesional aceptó primero, el cliente ya eligió otra propuesta, etc.). La UI debe mostrar
/// "esto cambió, actualizá la pantalla", nunca un error genérico.
class ServiceConflictFailure extends ServiceFailure {
  const ServiceConflictFailure();
}

/// 5xx o sin conexión — el backend no está disponible.
class ServiceServiceUnavailableFailure extends ServiceFailure {
  const ServiceServiceUnavailableFailure();
}
