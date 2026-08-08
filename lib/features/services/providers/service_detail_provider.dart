import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services_repository_provider.dart';

/// Detalle de un `Service` por su `id` (UUID) — online-only, `autoDispose` (ver
/// `openspec/decisions.md`).
final serviceDetailProvider =
    FutureProvider.autoDispose.family((ref, String id) {
  return ref.watch(servicesRepositoryProvider).fetchServiceDetail(id);
});
