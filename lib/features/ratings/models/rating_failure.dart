/// Errores de `POST /ratings`/`POST /ratings/professional-to-client` — mismo criterio que
/// `PaymentFailure`: la regla de negocio `ALREADY_RATED` viaja como 400 con un mensaje textual ya
/// en español, no como un código propio a interpretar (ver `openspec/decisions.md`). En la
/// práctica esta fase la evita proactivamente (chequea `GET /ratings/service/:id` antes de
/// mostrar el botón, ver `service_ratings_provider.dart`), pero igual se propaga tal cual por si
/// dos calificaciones llegan casi al mismo tiempo.
sealed class RatingFailure implements Exception {
  const RatingFailure();
}

class RatingValidationFailure extends RatingFailure {
  const RatingValidationFailure(this.backendMessage);

  final String? backendMessage;
}

class RatingServiceUnavailableFailure extends RatingFailure {
  const RatingServiceUnavailableFailure();
}
