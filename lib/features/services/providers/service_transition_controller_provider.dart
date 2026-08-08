import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_professional_services_provider.dart';
import 'services_repository_provider.dart';

/// Modo profesional: iniciar/completar un servicio asignado (`POST /services/:id/start`,
/// `POST /services/:id/complete`) — un solo controller para ambas transiciones, son la misma
/// operación de servidor conceptual ("avanzar el estado de mi servicio asignado").
class ServiceTransitionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> start(String serviceId) => _run(
        () => ref.read(servicesRepositoryProvider).startService(serviceId),
      );

  Future<void> complete(String serviceId) => _run(
        () => ref.read(servicesRepositoryProvider).completeService(serviceId),
      );

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await action();
      ref.invalidate(myProfessionalServicesProvider);
    });
  }
}

final serviceTransitionControllerProvider =
    AsyncNotifierProvider<ServiceTransitionController, void>(
  ServiceTransitionController.new,
);
