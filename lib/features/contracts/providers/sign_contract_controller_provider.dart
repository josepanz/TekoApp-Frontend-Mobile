import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import 'contract_provider.dart';
import 'contracts_repository_provider.dart';
import 'my_contracts_provider.dart';

/// Firma el contrato (cliente o profesional, según a quién le toca) — 409 si ya lo firmó o si
/// todavía no es su turno (ver `ContractsRepository._classify`).
class SignContractController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Contract?> sign(String contractReferenceId, String fullName) async {
    state = const AsyncLoading();
    Contract? updated;
    state = await AsyncValue.guard(() async {
      updated = await ref
          .read(contractsRepositoryProvider)
          .signContract(contractReferenceId, fullName);
      ref.invalidate(contractProvider(contractReferenceId));
      ref.invalidate(myContractsProvider);
    });
    return updated;
  }
}

final signContractControllerProvider =
    AsyncNotifierProvider<SignContractController, void>(
  SignContractController.new,
);
