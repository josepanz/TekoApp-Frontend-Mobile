/// Estado de sesión mínimo para que `go_router` pueda armar sus guards desde la Fase 0001.
///
/// A propósito NO incluye tokens ni datos de usuario todavía — el flujo real de login
/// (nonce + RSA-OAEP + Basic Auth de cliente, ver `.claude/rules/auth.md`) y el mecanismo de
/// almacenamiento seguro se implementan en la Fase 0002, una vez confirmado el paquete de storage
/// en `openspec/decisions.md`. Este placeholder deja el punto de extensión listo sin adelantarse
/// a esa decisión.
sealed class SessionState {
  const SessionState();
}

class SessionUnknown extends SessionState {
  const SessionUnknown();
}

class SessionAuthenticated extends SessionState {
  const SessionAuthenticated();
}

class SessionUnauthenticated extends SessionState {
  const SessionUnauthenticated();
}
