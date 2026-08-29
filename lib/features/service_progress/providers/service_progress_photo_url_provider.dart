import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_progress_repository_provider.dart';

/// Resuelve la URL presignada de una foto de bitácora a partir de su key de S3 — `autoDispose`,
/// nunca cacheada más allá del widget que la muestra (ver `.claude/rules/auth.md`).
final serviceProgressPhotoUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, key) {
  return ref.watch(serviceProgressRepositoryProvider).resolvePhotoUrl(key);
});
