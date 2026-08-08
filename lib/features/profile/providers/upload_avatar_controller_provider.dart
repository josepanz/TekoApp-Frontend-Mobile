import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import 'profile_repository_provider.dart';

/// Mutación de avatar — 2 pasos del backend en uno (`POST /uploads/avatar` → `PUT /auth/me
/// {avatarKey}`, ver `openspec/project.md`), expuesto como una sola operación del lado cliente.
class UploadAvatarController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(profileRepositoryProvider);
      final avatarKey = await repository.uploadAvatar(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );
      await repository.updateMe(avatarKey: avatarKey);
      await ref.read(sessionProvider.notifier).refreshAfterLogin();
    });
  }
}

final uploadAvatarControllerProvider =
    AsyncNotifierProvider<UploadAvatarController, void>(
  UploadAvatarController.new,
);
