import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers/service_detail_provider.dart';
import 'budget_options_provider.dart';
import 'budgets_repository_provider.dart';

/// Modo cliente: elegir una opción de presupuesto (`PATCH .../select`) — mismo efecto que aceptar
/// la `ServiceRequests` (competidoras auto-rechazadas server-side, ver
/// `RespondToRequestController`).
class SelectBudgetOptionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> select(
    String serviceId,
    String requestId,
    String optionReferenceId,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(budgetsRepositoryProvider)
          .selectBudgetOption(serviceId, requestId, optionReferenceId);
      ref.invalidate(serviceDetailProvider(serviceId));
      ref.invalidate(
        budgetOptionsProvider((serviceId: serviceId, requestId: requestId)),
      );
    });
  }
}

final selectBudgetOptionControllerProvider =
    AsyncNotifierProvider<SelectBudgetOptionController, void>(
  SelectBudgetOptionController.new,
);
