import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request.dart';
import 'available_services_provider.dart';
import 'services_repository_provider.dart';

/// Modo profesional: proponerse sobre un servicio disponible (`POST /services/:id/requests`) — ya
/// no manda `proposedPrice` (Fase 0009: el precio ahora se arma con opciones de presupuesto en
/// `BudgetBuilderScreen`, que se abre con la `ServiceRequest` que devuelve `submit()`).
class ProposeOnServiceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<ServiceRequest?> submit(String serviceId) async {
    state = const AsyncLoading();
    ServiceRequest? created;
    state = await AsyncValue.guard(() async {
      created = await ref
          .read(servicesRepositoryProvider)
          .proposeOnService(serviceId);
      // El servicio puede dejar de estar disponible (409) o simplemente ya no listarse como
      // "sin mi propuesta" — refrescar el listado tras proponerse.
      ref.invalidate(availableServicesProvider);
    });
    return created;
  }
}

final proposeOnServiceControllerProvider =
    AsyncNotifierProvider<ProposeOnServiceController, void>(
  ProposeOnServiceController.new,
);
