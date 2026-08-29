import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import 'contracts_repository_provider.dart';

/// Genera el contrato a partir de la `BudgetOptions` recién seleccionada — idempotente del lado
/// backend (llamar dos veces devuelve el mismo contrato, no falla).
class GenerateContractController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Contract?> generate(String budgetOptionReferenceId) async {
    state = const AsyncLoading();
    Contract? created;
    state = await AsyncValue.guard(() async {
      created = await ref
          .read(contractsRepositoryProvider)
          .generateContract(budgetOptionReferenceId);
    });
    return created;
  }
}

final generateContractControllerProvider =
    AsyncNotifierProvider<GenerateContractController, void>(
  GenerateContractController.new,
);
