import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_state.dart';

/// Placeholder de Fase 0001 — siempre resuelve "sin sesión". Se reemplaza en la Fase 0002 por un
/// `AsyncNotifier` real que llama `GET /auth/scope` al arrancar la app (nunca decodifica el JWT
/// del lado cliente, ver `.claude/rules/auth.md`) y expone login/logout.
final sessionProvider = Provider<SessionState>((ref) {
  return const SessionUnauthenticated();
});
