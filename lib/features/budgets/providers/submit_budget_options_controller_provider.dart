import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget_option.dart';
import 'budget_options_provider.dart';
import 'budgets_repository_provider.dart';

/// Modo profesional: enviar el set completo de opciones de presupuesto de una propuesta
/// (`PUT .../budget-options`).
class SubmitBudgetOptionsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit(
    String serviceId,
    String requestId,
    List<BudgetOptionDraft> options,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(budgetsRepositoryProvider)
          .replaceBudgetOptions(serviceId, requestId, options);
      ref.invalidate(
        budgetOptionsProvider((serviceId: serviceId, requestId: requestId)),
      );
    });
  }
}

final submitBudgetOptionsControllerProvider =
    AsyncNotifierProvider<SubmitBudgetOptionsController, void>(
  SubmitBudgetOptionsController.new,
);
