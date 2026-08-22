import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/locations_repository.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>((ref) {
  return LocationsRepository(ref.watch(apiClientProvider));
});
