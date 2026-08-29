import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/contracts_repository.dart';

final contractsRepositoryProvider = Provider<ContractsRepository>((ref) {
  return ContractsRepository(ref.watch(apiClientProvider));
});
