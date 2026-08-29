import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contract.dart';
import 'contracts_repository_provider.dart';

final myContractsProvider =
    FutureProvider.autoDispose<List<MyContractSummary>>((ref) {
  return ref.watch(contractsRepositoryProvider).fetchMyContracts();
});
