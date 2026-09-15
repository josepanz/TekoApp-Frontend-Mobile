import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_portfolio_provider.dart';
import 'professional_portfolio_repository_provider.dart';

class UploadPortfolioItemController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? caption,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(professionalPortfolioRepositoryProvider).upload(
            bytes: bytes,
            filename: filename,
            mimeType: mimeType,
            caption: caption,
          );
      ref.invalidate(myPortfolioProvider);
    });
  }
}

final uploadPortfolioItemControllerProvider =
    AsyncNotifierProvider<UploadPortfolioItemController, void>(
  UploadPortfolioItemController.new,
);
