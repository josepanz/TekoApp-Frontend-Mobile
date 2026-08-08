import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../professional_profile/providers/my_professional_profile_provider.dart';
import '../models/service.dart';
import 'services_repository_provider.dart';

/// Servicios PENDING sin profesional asignado en la categoría del profesional autenticado — no
/// existe un endpoint dedicado en el backend, se arma con `GET /services?status=PENDING&
/// categoryId=` (ver `openspec/decisions.md`). Lista vacía si el profesional todavía no tiene
/// perfil (no debería alcanzarse en la práctica, el gate de `/profesional` ya lo previene).
final availableServicesProvider = FutureProvider.autoDispose<List<Service>>((
  ref,
) async {
  final profile = await ref.watch(myProfessionalProfileProvider.future);
  if (profile == null) return const [];
  return ref
      .watch(servicesRepositoryProvider)
      .fetchAvailableServices(categoryId: profile.categoryId);
});
