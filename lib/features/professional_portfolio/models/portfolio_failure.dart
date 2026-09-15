/// Errores de cualquier operación sobre `professional_portfolio` — mismo criterio que
/// `ProfessionalDocumentFailure`. `CONSENT_REQUIRED` (403) NO cae acá: lo intercepta globalmente
/// `ConsentRequiredInterceptor` (`core/api_client`) antes de llegar al repositorio.
sealed class PortfolioFailure implements Exception {
  const PortfolioFailure();
}

/// 404 — la foto no existe, o no pertenece al profesional autenticado.
class PortfolioItemNotFoundFailure extends PortfolioFailure {
  const PortfolioItemNotFoundFailure(this.backendMessage);

  final String? backendMessage;
}

/// 400 — archivo demasiado grande o tipo no permitido.
class PortfolioValidationFailure extends PortfolioFailure {
  const PortfolioValidationFailure(this.backendMessage);

  final String? backendMessage;
}

class PortfolioServiceUnavailableFailure extends PortfolioFailure {
  const PortfolioServiceUnavailableFailure();
}
