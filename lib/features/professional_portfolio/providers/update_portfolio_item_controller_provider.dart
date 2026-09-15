import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_portfolio_provider.dart';
import 'professional_portfolio_repository_provider.dart';

class UpdatePortfolioItemController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(
    String referenceId, {
    String? caption,
    int? sortOrder,
    bool? isVisible,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(professionalPortfolioRepositoryProvider).update(
            referenceId,
            caption: caption,
            sortOrder: sortOrder,
            isVisible: isVisible,
          );
      ref.invalidate(myPortfolioProvider);
    });
  }
}

final updatePortfolioItemControllerProvider =
    AsyncNotifierProvider<UpdatePortfolioItemController, void>(
  UpdatePortfolioItemController.new,
);
