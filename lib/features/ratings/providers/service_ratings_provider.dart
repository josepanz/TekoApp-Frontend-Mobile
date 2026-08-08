import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/rating.dart';
import 'ratings_repository_provider.dart';

/// Calificaciones ya existentes para un `Service` — se usa para ocultar el botón "calificar" si
/// ya se calificó, pedido explícito de la tarea (ver
/// `openspec/changes/0004-payments-and-ratings.md`), no solo manejar el 400 `ALREADY_RATED`.
final serviceRatingsProvider =
    FutureProvider.autoDispose.family<List<Rating>, String>((ref, serviceId) {
  return ref.watch(ratingsRepositoryProvider).fetchForService(serviceId);
});
