import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/professional_rating_stats.dart';
import 'ratings_repository_provider.dart';

/// Estadísticas de un profesional (recibidas como profesional) — `professionalId` es el id
/// interno (Int) de `Professionals`, no el `referenceId`, ver `ratings_repository.fetchProfessionalStats`.
final professionalRatingStatsProvider = FutureProvider.autoDispose
    .family<ProfessionalRatingStats, int>((ref, professionalId) {
  return ref
      .watch(ratingsRepositoryProvider)
      .fetchProfessionalStats(professionalId);
});
