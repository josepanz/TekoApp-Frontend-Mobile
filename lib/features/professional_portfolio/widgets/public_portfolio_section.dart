import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../models/portfolio_item.dart';
import '../providers/portfolio_file_url_provider.dart';
import '../providers/public_portfolio_provider.dart';

/// Sección "Trabajos anteriores" del lado cliente — solo fotos aprobadas y visibles (el backend
/// ya filtra, `GET .../portfolio/public`). Mismo punto de contacto que
/// `ProfessionalDocumentsSection` (detalle de servicio, ver `openspec/decisions.md`).
class PublicPortfolioSection extends ConsumerWidget {
  const PublicPortfolioSection({
    super.key,
    required this.professionalReferenceId,
  });

  final String professionalReferenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final portfolioAsync = ref.watch(
      publicPortfolioProvider(professionalReferenceId),
    );
    final items = portfolioAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.publicPortfolioSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AsyncStateView<List<PortfolioItem>>(
          isLoading: portfolioAsync.isLoading,
          hasError: portfolioAsync.hasError,
          data: items,
          isEmpty: items != null && items.isEmpty,
          errorMessage: l10n.publicPortfolioSectionError,
          emptyMessage: l10n.publicPortfolioSectionEmpty,
          builder: (context, items) => SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) =>
                  _PublicPortfolioPhoto(item: items[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _PublicPortfolioPhoto extends ConsumerWidget {
  const _PublicPortfolioPhoto({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileUrlAsync = ref.watch(portfolioFileUrlProvider(item.fileKey));

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: switch (fileUrlAsync) {
        AsyncData(:final value) => Image.network(
            value,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        // Placeholder estático (no un spinner animado): evita el problema clásico de
        // `pumpAndSettle()` con animaciones indefinidas en los tests — ver `teko_avatar_test.dart`
        // para el mismo criterio de no mockear `Image.network`.
        _ => Container(
            width: 88,
            height: 88,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
      },
    );
  }
}
