import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/promotions_repository.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>((ref) {
  return PromotionsRepository(ref.watch(apiClientProvider));
});
