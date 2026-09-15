import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_portfolio_provider.dart';
import 'professional_portfolio_repository_provider.dart';

class DeletePortfolioItemController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(String referenceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(professionalPortfolioRepositoryProvider)
          .delete(referenceId);
      ref.invalidate(myPortfolioProvider);
    });
  }
}

final deletePortfolioItemControllerProvider =
    AsyncNotifierProvider<DeletePortfolioItemController, void>(
  DeletePortfolioItemController.new,
);
