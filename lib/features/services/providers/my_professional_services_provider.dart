import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services_repository_provider.dart';

/// "Mis servicios" (modo profesional) — servicios asignados (ACCEPTED/IN_PROGRESS/COMPLETED/
/// CANCELLED con `professionalId` = yo). Online-only, `autoDispose` (ver
/// `openspec/decisions.md`).
final myProfessionalServicesProvider = FutureProvider.autoDispose((ref) {
  return ref
      .watch(servicesRepositoryProvider)
      .fetchMyServices(role: 'professional');
});
