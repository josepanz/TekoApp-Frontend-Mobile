/// Errores de cualquier operación sobre `service_progress` (crear/listar/eliminar entradas) —
/// mismo criterio que `ServiceFailure`: cargar el mensaje textual del backend cuando aplica, nunca
/// inventar uno propio para casos que el backend ya distingue.
sealed class ServiceProgressFailure implements Exception {
  const ServiceProgressFailure();
}

/// 403 — no sos el profesional asignado (crear), no sos el autor (eliminar), o no tenés permiso
/// para ver esta bitácora (listar). El consentimiento de imagen (`CONSENT_REQUIRED`) NO cae acá —
/// lo intercepta globalmente `ConsentRequiredInterceptor` (`core/api_client`) antes de llegar a
/// este repositorio, reintentando el request original tras la aceptación.
class ServiceProgressForbiddenFailure extends ServiceProgressFailure {
  const ServiceProgressForbiddenFailure(this.backendMessage);

  final String? backendMessage;
}

/// 409 — el servicio no está ACCEPTED/IN_PROGRESS (crear), o ya venció la ventana de corrección
/// (eliminar).
class ServiceProgressConflictFailure extends ServiceProgressFailure {
  const ServiceProgressConflictFailure(this.backendMessage);

  final String? backendMessage;
}

/// 400 — falta nota/foto obligatoria, o se superó el máximo de fotos por entrada.
class ServiceProgressValidationFailure extends ServiceProgressFailure {
  const ServiceProgressValidationFailure(this.backendMessage);

  final String? backendMessage;
}

/// 404 — el servicio o la entrada referenciada no existen.
class ServiceProgressNotFoundFailure extends ServiceProgressFailure {
  const ServiceProgressNotFoundFailure();
}

class ServiceProgressServiceUnavailableFailure extends ServiceProgressFailure {
  const ServiceProgressServiceUnavailableFailure();
}
