import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/professional_portfolio_repository.dart';

final professionalPortfolioRepositoryProvider =
    Provider<ProfessionalPortfolioRepository>((ref) {
  return ProfessionalPortfolioRepository(ref.watch(apiClientProvider));
});
