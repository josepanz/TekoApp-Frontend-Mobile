import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/ai_disclosures_repository.dart';

final aiDisclosuresRepositoryProvider = Provider<AiDisclosuresRepository>((
  ref,
) {
  return AiDisclosuresRepository(ref.watch(apiClientProvider));
});
