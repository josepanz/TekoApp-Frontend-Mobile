import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client/api_client_provider.dart';
import '../data/auth_repository.dart';

/// Un provider por operación de servidor es la regla (ver
/// `.claude/rules/flutter-architecture.md`) — este expone la instancia del repositorio; los
/// providers de login/logout/refresh en sí se agregan en la Fase 0002, cada uno separado (nunca
/// un provider único que mezcle las tres operaciones).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
