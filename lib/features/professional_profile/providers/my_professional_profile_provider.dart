import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/professional_profile.dart';
import 'professional_profile_repository_provider.dart';

/// `null` = todavía no tiene perfil profesional (no es un error). `AsyncError` = servicio no
/// disponible. Online-only (`autoDispose`, ver `openspec/decisions.md`). El gate de `go_router`
/// (`app.dart`) lo lee para decidir si redirige a `/profesional/onboarding`.
final myProfessionalProfileProvider =
    FutureProvider.autoDispose<ProfessionalProfile?>((ref) {
  return ref.watch(professionalProfileRepositoryProvider).fetchMe();
});
