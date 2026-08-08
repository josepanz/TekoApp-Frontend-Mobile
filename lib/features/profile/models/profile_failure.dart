/// Errores de `PUT /auth/me` (ver `openspec/specs/auth-and-session.md` — mismo criterio que
/// `LoginFailure`: nunca colapsar un error de validación con uno de disponibilidad del servicio).
sealed class ProfileFailure implements Exception {
  const ProfileFailure();
}

/// 4xx — datos rechazados por el backend (ej. teléfono con formato inválido).
class ProfileValidationFailure extends ProfileFailure {
  const ProfileValidationFailure();
}

/// 5xx o sin conexión — el backend no está disponible, no es un problema de los datos enviados.
class ProfileServiceUnavailableFailure extends ProfileFailure {
  const ProfileServiceUnavailableFailure();
}

/// Errores de `POST /uploads/avatar` — los 2 primeros se detectan ANTES de la request (mismo
/// límite que `TekoApp-Backend/src/api/uploads/const/uploads.const.ts`), para dar un mensaje
/// específico sin gastar una subida completa (ver `openspec/specs/auth-and-session.md`, "Subida
/// de avatar fallida → mensaje específico, no un error genérico").
sealed class AvatarUploadFailure implements Exception {
  const AvatarUploadFailure();
}

class AvatarTooLargeFailure extends AvatarUploadFailure {
  const AvatarTooLargeFailure();
}

class AvatarUnsupportedTypeFailure extends AvatarUploadFailure {
  const AvatarUnsupportedTypeFailure();
}

/// El backend rechazó el archivo (400) por una razón no anticipada por la validación del cliente,
/// o el servicio no está disponible (5xx/sin conexión) — no se distinguen entre sí acá porque en
/// ambos casos la UI muestra el mismo "no se pudo subir la imagen, probá de nuevo".
class AvatarUploadServiceFailure extends AvatarUploadFailure {
  const AvatarUploadServiceFailure();
}
