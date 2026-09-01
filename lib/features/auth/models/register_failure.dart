/// Estados de error del registro que la UI debe distinguir — mismo criterio que `LoginFailure`
/// (nunca colapsar un error de negocio real con uno de red/servidor).
sealed class RegisterFailure implements Exception {
  const RegisterFailure();
}

/// 409 — el email ya está registrado (`OnboardingService.registerUser`, `USER_ALREADY_EXISTS`).
class EmailAlreadyRegisteredFailure extends RegisterFailure {
  const EmailAlreadyRegisteredFailure();
}

/// Error de red (sin conexión, timeout) — el dispositivo no llegó a hablar con el servidor.
/// Nombre con prefijo `Register` a propósito: `login_failure.dart` ya define un
/// `NoConnectionFailure` propio (sealed en su propia jerarquía) — mismo concepto, jerarquías
/// distintas, así que no pueden compartir el nombre en el mismo library import.
class RegisterNoConnectionFailure extends RegisterFailure {
  const RegisterNoConnectionFailure();
}

/// El servidor respondió pero con un error (4xx/5xx) — llegó al backend, pero algo falló ahí.
class RegisterServiceUnavailableFailure extends RegisterFailure {
  const RegisterServiceUnavailableFailure();
}
