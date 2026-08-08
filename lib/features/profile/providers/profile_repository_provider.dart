import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});
