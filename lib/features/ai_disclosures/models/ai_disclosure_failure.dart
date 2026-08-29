/// Errores de `PUT`/`DELETE` de `ai_disclosures` — mismo criterio que `LegalConsentsFailure`
/// (cargar el mensaje textual del backend en vez de inventar uno propio). `Forbidden` (403, no sos
/// el dueño) y `Validation` (400, tipo no declarable) se distinguen por status code — a diferencia
/// de `legal_consents`, acá el backend ya usa 403 real para "no dueño" (no un 409 genérico), así
/// que no hace falta mirar `errorCode`.
sealed class AiDisclosureFailure implements Exception {
  const AiDisclosureFailure();
}

class AiDisclosureNotFoundFailure extends AiDisclosureFailure {
  const AiDisclosureNotFoundFailure(this.backendMessage);

  final String? backendMessage;
}

/// 403 — el usuario no es dueño del contenido (al declarar) o de la declaración (al retirar).
class AiDisclosureForbiddenFailure extends AiDisclosureFailure {
  const AiDisclosureForbiddenFailure(this.backendMessage);

  final String? backendMessage;
}

/// 400 — `entityType` no está en `APP_CONFIG.aiDisclosure.userDeclarableTypes`.
class AiDisclosureValidationFailure extends AiDisclosureFailure {
  const AiDisclosureValidationFailure(this.backendMessage);

  final String? backendMessage;
}

class AiDisclosureServiceUnavailableFailure extends AiDisclosureFailure {
  const AiDisclosureServiceUnavailableFailure();
}
