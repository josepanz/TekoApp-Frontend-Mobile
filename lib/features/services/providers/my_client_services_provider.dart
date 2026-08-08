import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services_repository_provider.dart';

/// "Mis servicios" (modo cliente) — online-only (ver `openspec/decisions.md`): `autoDispose`
/// para que cada visita a la pantalla refetchee, sin caché entre sesiones.
final myClientServicesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(servicesRepositoryProvider).fetchMyServices(role: 'client');
});
