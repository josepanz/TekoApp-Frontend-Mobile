import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_item.dart';
import 'professional_portfolio_repository_provider.dart';

/// Fotos aprobadas y visibles al cliente, por `referenceId` del profesional.
final publicPortfolioProvider =
    FutureProvider.autoDispose.family<List<PortfolioItem>, String>((
  ref,
  professionalReferenceId,
) {
  return ref
      .watch(professionalPortfolioRepositoryProvider)
      .publicPortfolio(professionalReferenceId);
});
