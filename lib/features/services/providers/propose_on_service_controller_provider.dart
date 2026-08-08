import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'available_services_provider.dart';
import 'services_repository_provider.dart';

/// Modo profesional: proponerse sobre un servicio disponible (`POST /services/:id/requests`).
class ProposeOnServiceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(String serviceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(servicesRepositoryProvider).proposeOnService(serviceId);
      // El servicio puede dejar de estar disponible (409) o simplemente ya no listarse como
      // "sin mi propuesta" — refrescar el listado tras proponerse.
      ref.invalidate(availableServicesProvider);
    });
  }
}

final proposeOnServiceControllerProvider =
    AsyncNotifierProvider<ProposeOnServiceController, void>(
  ProposeOnServiceController.new,
);
