import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_request.dart';
import 'services_repository_provider.dart';

/// Propuestas (`ServiceRequests`) de un servicio propio — online-only, `autoDispose` (ver
/// `openspec/decisions.md`). Solo tiene sentido consultarlo mientras el servicio está PENDING.
final serviceRequestsProvider = FutureProvider.autoDispose
    .family<List<ServiceRequest>, String>((ref, serviceId) {
  return ref.watch(servicesRepositoryProvider).fetchServiceRequests(serviceId);
});
