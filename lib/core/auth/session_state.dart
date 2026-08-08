import 'user_summary.dart';

/// Estado de sesión real desde la Fase 0002 — antes placeholder, ver `session_provider.dart`.
///
/// `SessionUnknown` es el estado inicial mientras `GET /auth/scope` (con el `accessToken`
/// guardado, si existe) todavía no resolvió. `SessionServiceUnavailable` es un estado propio,
/// distinto de `SessionUnauthenticated` — 5xx/sin conexión NUNCA deben tratarse como "no hay
/// sesión" (ver `openspec/specs/auth-and-session.md`, mismo bug ya corregido en `TekoApp-Web`).
sealed class SessionState {
  const SessionState();
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionAuthenticated extends SessionState {
  const SessionAuthenticated(this.user);

  final UserSummary user;
}

class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}

class SessionServiceUnavailable extends SessionState {
  const SessionServiceUnavailable();
}
