import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/professional_profile_repository.dart';

final professionalProfileRepositoryProvider =
    Provider<ProfessionalProfileRepository>((ref) {
  return ProfessionalProfileRepository(ref.watch(apiClientProvider));
});
