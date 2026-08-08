import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/models/scope_failure.dart';
import '../../features/auth/providers/auth_repository_provider.dart';
import 'session_state.dart';
import 'user_summary.dart';

/// Sesión real (ver `openspec/changes/0002-auth-and-design-system.md`) — antes placeholder
/// siempre-sin-sesión. Al construirse: si hay un `accessToken` guardado, llama `GET /auth/scope`
/// para traer datos frescos (nunca decodifica el JWT, ver `.claude/rules/auth.md`). Un 401 ya
/// intentó refrescar transparentemente vía `RefreshTokenInterceptor` — si `fetchScope()` todavía
/// lanza `SessionExpiredFailure` es porque el refresh también falló.
class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    _restoreSession();
    return const SessionUnknown();
  }

  Future<void> _restoreSession() async {
    final repository = ref.read(authRepositoryProvider);
    final accessToken = await repository.readAccessToken();
    if (accessToken == null) {
      state = const SessionUnauthenticated();
      return;
    }
    await _refreshScope(repository);
  }

  Future<void> _refreshScope(AuthRepository repository) async {
    try {
      final user = await repository.fetchScope();
      state = SessionAuthenticated(user);
    } on SessionExpiredFailure {
      await repository.clearSession();
      state = const SessionUnauthenticated();
    } on ScopeUnavailableFailure {
      state = const SessionServiceUnavailable();
    }
  }

  void setAuthenticated(UserSummary user) {
    state = SessionAuthenticated(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).clearSession();
    state = const SessionUnauthenticated();
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);
