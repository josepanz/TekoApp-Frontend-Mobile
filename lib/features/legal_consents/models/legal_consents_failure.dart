/// Errores de cualquier operación de `legal_consents` — mismo criterio que `PaymentFailure`
/// (cargar el mensaje textual del backend en vez de inventar uno propio). `LegalHold` se distingue
/// de un 409 genérico vía el campo `errorCode: 'LEGAL_HOLD_ACTIVE'` del envelope de error (ver
/// `TekoApp-Backend/openspec/decisions.md`, amendment 2026-08-25) — sin eso, la UI no podría
/// mostrar el motivo específico en vez de un error genérico, como pide
/// `openspec/specs/data-and-media-consent.md`.
sealed class LegalConsentsFailure implements Exception {
  const LegalConsentsFailure();
}

class LegalConsentsNotFoundFailure extends LegalConsentsFailure {
  const LegalConsentsNotFoundFailure(this.backendMessage);

  final String? backendMessage;
}

/// 409 sin `errorCode` — hoy solo "ya aceptaste esta versión" / "no sos dueño del contenido".
class LegalConsentsConflictFailure extends LegalConsentsFailure {
  const LegalConsentsConflictFailure(this.backendMessage);

  final String? backendMessage;
}

/// 409 con `errorCode: 'LEGAL_HOLD_ACTIVE'`.
class LegalConsentsLegalHoldFailure extends LegalConsentsFailure {
  const LegalConsentsLegalHoldFailure(this.backendMessage);

  final String? backendMessage;
}

class LegalConsentsValidationFailure extends LegalConsentsFailure {
  const LegalConsentsValidationFailure(this.backendMessage);

  final String? backendMessage;
}

class LegalConsentsServiceUnavailableFailure extends LegalConsentsFailure {
  const LegalConsentsServiceUnavailableFailure();
}
