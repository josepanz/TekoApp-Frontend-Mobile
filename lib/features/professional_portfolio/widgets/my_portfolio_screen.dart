import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_badge.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/portfolio_item.dart';
import '../models/portfolio_review_status.dart';
import '../providers/delete_portfolio_item_controller_provider.dart';
import '../providers/my_portfolio_provider.dart';
import '../providers/portfolio_file_url_provider.dart';
import '../providers/update_portfolio_item_controller_provider.dart';
import 'upload_portfolio_item_sheet.dart';

/// "Mi portafolio" (profesional) — grilla de fotos con estado, visibilidad y borrado. Ver
/// `TekoApp-Backend/openspec/specs/professional-onboarding-and-portfolio.md`, Fase 4-5.
class MyPortfolioScreen extends ConsumerWidget {
  const MyPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final portfolioAsync = ref.watch(myPortfolioProvider);
    final items = portfolioAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myPortfolioScreenTitle)),
      floatingActionButton: FloatingActionButton(
        key: const Key('my_portfolio_upload_button'),
        tooltip: l10n.portfolioUploadButton,
        onPressed: () => showUploadPortfolioItemSheet(context),
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AsyncStateView<List<PortfolioItem>>(
          isLoading: portfolioAsync.isLoading,
          hasError: portfolioAsync.hasError,
          data: items,
          isEmpty: items != null && items.isEmpty,
          errorMessage: l10n.myPortfolioError,
          emptyMessage: l10n.myPortfolioEmpty,
          builder: (context, items) => ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _PortfolioItemCard(item: items[index]),
          ),
        ),
      ),
    );
  }
}

class _PortfolioItemCard extends ConsumerWidget {
  const _PortfolioItemCard({required this.item});

  final PortfolioItem item;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.portfolioDeleteConfirmTitle),
        content: Text(l10n.portfolioDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.uploadPortfolioItemCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.portfolioDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(deletePortfolioItemControllerProvider.notifier)
        .submit(item.referenceId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final fileUrlAsync = ref.watch(portfolioFileUrlProvider(item.fileKey));

    return TekoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: switch (fileUrlAsync) {
              AsyncData(:final value) => Image.network(
                  value,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              // Placeholder estático (no un spinner animado): evita el problema clásico de
              // `pumpAndSettle()` con animaciones indefinidas en los tests de esta pantalla — ver
              // `teko_avatar_test.dart` para el mismo criterio de no mockear `Image.network`.
              _ => Container(
                  width: 72,
                  height: 72,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: item.status),
                if (item.caption != null) ...[
                  const SizedBox(height: 4),
                  Text(item.caption!),
                ],
                if (item.status == PortfolioReviewStatus.rejected &&
                    item.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.rejectionReason!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Switch(
                      key: Key('portfolio_visible_switch_${item.referenceId}'),
                      value: item.isVisible,
                      onChanged: (checked) => ref
                          .read(updatePortfolioItemControllerProvider.notifier)
                          .submit(item.referenceId, isVisible: checked),
                    ),
                    Text(l10n.portfolioVisibleLabel),
                    const Spacer(),
                    TekoButton(
                      key: Key('portfolio_delete_button_${item.referenceId}'),
                      label: l10n.portfolioDeleteButton,
                      variant: TekoButtonVariant.ghost,
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PortfolioReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      PortfolioReviewStatus.pending => TekoBadge(
          label: l10n.portfolioStatusPending,
          variant: TekoBadgeVariant.warning,
        ),
      PortfolioReviewStatus.approved => TekoBadge(
          label: l10n.portfolioStatusApproved,
          variant: TekoBadgeVariant.success,
        ),
      PortfolioReviewStatus.rejected => TekoBadge(
          label: l10n.portfolioStatusRejected,
          variant: TekoBadgeVariant.destructive,
        ),
    };
  }
}
