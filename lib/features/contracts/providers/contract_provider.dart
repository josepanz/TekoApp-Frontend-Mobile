import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import 'contracts_repository_provider.dart';

/// Un contrato puntual — `autoDispose`, online-only (mismo criterio que `budgetOptionsProvider`).
final contractProvider =
    FutureProvider.autoDispose.family<Contract, String>((ref, referenceId) {
  return ref.watch(contractsRepositoryProvider).fetchContract(referenceId);
});
