import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/account_deletion_repository.dart';

final accountDeletionRepositoryProvider =
    Provider<AccountDeletionRepository>((ref) {
  return AccountDeletionRepository(ref.watch(apiClientProvider));
});
