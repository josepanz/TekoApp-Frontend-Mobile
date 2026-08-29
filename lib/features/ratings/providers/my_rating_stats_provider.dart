import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_rating_stats.dart';
import 'ratings_repository_provider.dart';

/// Mis estadísticas propias como cliente (dadas/recibidas) — ver `ratings_repository.fetchMyStats`.
final myRatingStatsProvider = FutureProvider.autoDispose<UserRatingStats>((
  ref,
) {
  return ref.watch(ratingsRepositoryProvider).fetchMyStats();
});
