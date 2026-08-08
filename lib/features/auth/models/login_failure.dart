/// Los 3 estados de error del login que la UI debe distinguir (ver
/// `openspec/changes/0002-auth-and-design-system.md` y `openspec/specs/auth-and-session.md`) — nunca
/// colapsar 401 con 5xx/sin-conexión ("credenciales inválidas" es un mensaje de seguridad
/// deliberadamente genérico, no aplica a fallas de red o del servidor).
sealed class LoginFailure implements Exception {
  const LoginFailure();
}

/// 401 — email o password incorrectos. Nunca distinguir cuál de los dos falló.
class InvalidCredentialsFailure extends LoginFailure {
  const InvalidCredentialsFailure();
}

/// Error de red (sin conexión, timeout) — el dispositivo no llegó a hablar con el servidor.
class NoConnectionFailure extends LoginFailure {
  const NoConnectionFailure();
}

/// El servidor respondió pero con un error (5xx) — llegó al backend, pero algo falló ahí.
class ServiceUnavailableFailure extends LoginFailure {
  const ServiceUnavailableFailure();
}
