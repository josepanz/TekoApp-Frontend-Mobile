import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_progress_provider.dart';
import 'service_progress_repository_provider.dart';

typedef PendingProgressPhoto = ({
  Uint8List bytes,
  String filename,
  String mimeType,
});

/// Mutaciones de bitácora — crear (con 0+ fotos, subidas antes una por una vía
/// `ServiceProgressRepository.uploadImage`) y eliminar. Invalida `serviceProgressProvider` del
/// `serviceId` correspondiente tras cada mutación exitosa, mismo patrón que
/// `ServiceTransitionController`.
class ServiceProgressController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addEntry({
    required String serviceId,
    String? note,
    List<PendingProgressPhoto> photos = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(serviceProgressRepositoryProvider);
      final imageKeys = <String>[];
      for (final photo in photos) {
        final key = await repository.uploadImage(
          bytes: photo.bytes,
          filename: photo.filename,
          mimeType: photo.mimeType,
        );
        imageKeys.add(key);
      }
      await repository.createEntry(
        serviceId: serviceId,
        note: note,
        images: imageKeys,
      );
      ref.invalidate(serviceProgressProvider(serviceId));
    });
  }

  Future<void> deleteEntry({
    required String serviceId,
    required String entryId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(serviceProgressRepositoryProvider)
          .deleteEntry(serviceId: serviceId, entryId: entryId);
      ref.invalidate(serviceProgressProvider(serviceId));
    });
  }
}

final serviceProgressControllerProvider =
    AsyncNotifierProvider<ServiceProgressController, void>(
  ServiceProgressController.new,
);
