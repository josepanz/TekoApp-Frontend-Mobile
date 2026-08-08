/// Resultado de error de `AuthRepository.fetchScope()` — a diferencia de `LoginFailure`, acá
/// 5xx y sin-conexión SÍ se colapsan en un solo estado (`ScopeUnavailableFailure`): el spec exige
/// que ninguno de los dos redirija a login, así que la UI no necesita distinguirlos (ver
/// `openspec/specs/auth-and-session.md`, sección "Sesión activa").
sealed class ScopeFailure implements Exception {
  const ScopeFailure();
}

/// 401 tras el refresh automático (`RefreshTokenInterceptor`) también fallar — sesión vencida de
/// verdad, corresponde cerrar sesión localmente y navegar a login.
class SessionExpiredFailure extends ScopeFailure {
  const SessionExpiredFailure();
}

/// 5xx o error de red — "no sabemos si hay sesión", nunca "no hay sesión". Nunca navegar a login.
class ScopeUnavailableFailure extends ScopeFailure {
  const ScopeUnavailableFailure();
}
