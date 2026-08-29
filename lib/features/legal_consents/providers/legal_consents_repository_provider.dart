import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/legal_consents_repository.dart';

final legalConsentsRepositoryProvider = Provider<LegalConsentsRepository>((
  ref,
) {
  return LegalConsentsRepository(ref.watch(apiClientProvider));
});
