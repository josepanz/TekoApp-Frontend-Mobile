import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client_provider.dart';
import '../../../core/auth/cookie_jar_provider.dart';
import '../data/auth_repository.dart';

/// Un provider por operación de servidor es la regla (ver
/// `.claude/rules/flutter-architecture.md`) — este expone la instancia del repositorio; los
/// providers de login/logout/refresh en sí se agregan por separado (nunca un provider único que
/// mezcle varias operaciones).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    cookieJar: ref.watch(cookieJarProvider),
  );
});
