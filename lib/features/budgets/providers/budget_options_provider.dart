import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget_option.dart';
import 'budgets_repository_provider.dart';

typedef BudgetOptionsKey = ({String serviceId, String requestId});

/// Opciones de presupuesto de una propuesta puntual — `autoDispose` (ver
/// `openspec/decisions.md`), online-only.
final budgetOptionsProvider = FutureProvider.autoDispose
    .family<List<BudgetOption>, BudgetOptionsKey>((ref, key) {
  return ref
      .watch(budgetsRepositoryProvider)
      .fetchBudgetOptions(key.serviceId, key.requestId);
});
