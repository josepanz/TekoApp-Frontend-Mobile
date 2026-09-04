import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'professional_portfolio_repository_provider.dart';

/// Resuelve la URL presignada de una foto a partir de su key de S3 — `autoDispose`, nunca
/// cacheada más allá del widget que la muestra.
final portfolioFileUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, key) {
  return ref.watch(professionalPortfolioRepositoryProvider).resolveFileUrl(key);
});
