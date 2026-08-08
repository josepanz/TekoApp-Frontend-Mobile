import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services_repository_provider.dart';

/// Mutación de "pedir servicio" — un provider por operación de servidor (ver
/// `.claude/rules/flutter-architecture.md`), separado del repositorio.
class RequestServiceController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String title,
    required String description,
    required int categoryId,
    required int serviceTypeId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(servicesRepositoryProvider).createService(
            title: title,
            description: description,
            categoryId: categoryId,
            serviceTypeId: serviceTypeId,
            latitude: latitude,
            longitude: longitude,
            address: address,
          );
    });
  }
}

final requestServiceControllerProvider =
    AsyncNotifierProvider<RequestServiceController, void>(
  RequestServiceController.new,
);
