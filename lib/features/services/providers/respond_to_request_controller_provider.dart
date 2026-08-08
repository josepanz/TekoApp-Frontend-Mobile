import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/request_status.dart';
import 'service_detail_provider.dart';
import 'service_requests_provider.dart';
import 'services_repository_provider.dart';

/// Modo cliente: aceptar una propuesta competidora sobre mi servicio PENDING
/// (`PUT /services/:id/requests/:requestId`) — las demás se rechazan solas server-side (ver
/// `openspec/decisions.md`), no hace falta iterar acá.
class RespondToRequestController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> accept(String serviceId, String requestId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(servicesRepositoryProvider)
          .respondToRequest(serviceId, requestId, RequestStatus.accepted);
      ref.invalidate(serviceDetailProvider(serviceId));
      ref.invalidate(serviceRequestsProvider(serviceId));
    });
  }
}

final respondToRequestControllerProvider =
    AsyncNotifierProvider<RespondToRequestController, void>(
  RespondToRequestController.new,
);
