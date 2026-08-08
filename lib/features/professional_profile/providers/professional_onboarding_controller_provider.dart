import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_professional_profile_provider.dart';
import 'professional_profile_repository_provider.dart';

/// Alta de perfil profesional (`POST /professionals`) — un provider por operación de servidor.
class ProfessionalOnboardingController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required int categoryId,
    required String description,
    required double hourlyRate,
    double? fixedRate,
    List<String>? skills,
    int? yearsOfExperience,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(professionalProfileRepositoryProvider).register(
            categoryId: categoryId,
            description: description,
            hourlyRate: hourlyRate,
            fixedRate: fixedRate,
            skills: skills,
            yearsOfExperience: yearsOfExperience,
          );
      // El gate de `/profesional` lee este provider — invalidarlo para que muestre el perfil
      // recién creado en vez del estado "sin perfil" cacheado.
      ref.invalidate(myProfessionalProfileProvider);
    });
  }
}

final professionalOnboardingControllerProvider =
    AsyncNotifierProvider<ProfessionalOnboardingController, void>(
  ProfessionalOnboardingController.new,
);
