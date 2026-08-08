import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ratings_repository_provider.dart';
import 'service_ratings_provider.dart';

/// Calificar (cliente→profesional o profesional→cliente) — comparte un `_run` entre ambos
/// sentidos, mismo criterio que `ServiceTransitionController` (start/complete).
class RateController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> rateProfessional({
    required String professionalReferenceId,
    required String serviceId,
    required double rating,
    String? comment,
  }) =>
      _run(
        serviceId,
        () => ref.read(ratingsRepositoryProvider).rateProfessional(
              professionalReferenceId: professionalReferenceId,
              serviceReferenceId: serviceId,
              rating: rating,
              comment: comment,
            ),
      );

  Future<void> rateClient({
    required String clientReferenceId,
    required String serviceId,
    required double rating,
    String? comment,
  }) =>
      _run(
        serviceId,
        () => ref.read(ratingsRepositoryProvider).rateClient(
              clientReferenceId: clientReferenceId,
              serviceReferenceId: serviceId,
              rating: rating,
              comment: comment,
            ),
      );

  Future<void> _run(String serviceId, Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
      ref.invalidate(serviceRatingsProvider(serviceId));
    });
  }
}

final rateControllerProvider = AsyncNotifierProvider<RateController, void>(
  RateController.new,
);
