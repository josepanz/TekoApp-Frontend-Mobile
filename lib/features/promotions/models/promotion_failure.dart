/// Errores de `POST /promotions/validate`/`apply` — un código inválido/vencido/agotado NO cae
/// acá (el backend responde 200 con `isValid`/`success: false`, ver `PromotionValidation`/
/// `PromotionApplyResult`). Esto es solo para fallas reales de la petición (auth, red, 5xx).
sealed class PromotionFailure implements Exception {
  const PromotionFailure();
}

/// 4xx — ej. `serviceAmount` inválido.
class PromotionValidationFailure extends PromotionFailure {
  const PromotionValidationFailure();
}

/// 5xx o sin conexión.
class PromotionServiceUnavailableFailure extends PromotionFailure {
  const PromotionServiceUnavailableFailure();
}
