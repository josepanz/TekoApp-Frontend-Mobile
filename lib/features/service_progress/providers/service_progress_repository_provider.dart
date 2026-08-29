import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/service_progress_repository.dart';

final serviceProgressRepositoryProvider =
    Provider<ServiceProgressRepository>((ref) {
  return ServiceProgressRepository(ref.watch(apiClientProvider));
});
