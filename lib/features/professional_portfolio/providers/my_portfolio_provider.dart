import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_item.dart';
import 'professional_portfolio_repository_provider.dart';

/// "Mi portafolio" — online-only, `autoDispose` (mismo criterio que `myDocumentsProvider`).
final myPortfolioProvider = FutureProvider.autoDispose<List<PortfolioItem>>((
  ref,
) {
  return ref.watch(professionalPortfolioRepositoryProvider).myPortfolio();
});
