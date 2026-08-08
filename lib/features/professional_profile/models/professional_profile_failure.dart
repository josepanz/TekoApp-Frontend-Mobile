/// Errores de `POST /professionals` (activar perfil profesional) — mismo criterio que
/// `ProfileFailure`/`ServiceFailure`: nunca colapsar validación con disponibilidad del servicio.
sealed class ProfessionalProfileFailure implements Exception {
  const ProfessionalProfileFailure();
}

/// 4xx — incluye tanto datos rechazados (ej. `hourlyRate` negativo) como el caso de negocio
/// `USER_ALREADY_PROFESSIONAL` (el backend ya impide más de un perfil por usuario) — no se
/// distinguen entre sí, mismo criterio que el resto de los repos de esta app: un mensaje genérico
/// de "revisá los datos" alcanza para el alcance de esta fase.
class ProfessionalProfileValidationFailure extends ProfessionalProfileFailure {
  const ProfessionalProfileValidationFailure();
}

/// 5xx o sin conexión.
class ProfessionalProfileServiceUnavailableFailure
    extends ProfessionalProfileFailure {
  const ProfessionalProfileServiceUnavailableFailure();
}
