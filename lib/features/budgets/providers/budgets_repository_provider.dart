import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/budgets_repository.dart';

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(apiClientProvider));
});
