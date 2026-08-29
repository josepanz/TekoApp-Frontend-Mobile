/// Errores de cualquier operación sobre `professional_documents` — mismo criterio que
/// `ServiceProgressFailure`. `CONSENT_REQUIRED` (403) NO cae acá: lo intercepta globalmente
/// `ConsentRequiredInterceptor` (`core/api_client`) antes de llegar al repositorio.
sealed class ProfessionalDocumentFailure implements Exception {
  const ProfessionalDocumentFailure();
}

/// 404 — el tipo de documento no existe o no aplica a mi categoría profesional.
class ProfessionalDocumentTypeNotApplicableFailure
    extends ProfessionalDocumentFailure {
  const ProfessionalDocumentTypeNotApplicableFailure(this.backendMessage);

  final String? backendMessage;
}

/// 400 — archivo demasiado grande o tipo no permitido.
class ProfessionalDocumentValidationFailure extends ProfessionalDocumentFailure {
  const ProfessionalDocumentValidationFailure(this.backendMessage);

  final String? backendMessage;
}

class ProfessionalDocumentServiceUnavailableFailure
    extends ProfessionalDocumentFailure {
  const ProfessionalDocumentServiceUnavailableFailure();
}
