import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_progress_entry.dart';
import 'service_progress_repository_provider.dart';

/// Listado de la bitácora de un `Service` por su `id` (UUID) — online-only, `autoDispose`, mismo
/// criterio que `serviceDetailProvider`.
final serviceProgressProvider =
    FutureProvider.autoDispose.family<List<ServiceProgressEntry>, String>((
  ref,
  serviceId,
) {
  return ref.watch(serviceProgressRepositoryProvider).listByService(serviceId);
});
