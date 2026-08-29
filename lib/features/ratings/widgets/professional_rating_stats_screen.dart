import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_card.dart';
import '../../professional_profile/providers/my_professional_profile_provider.dart';
import '../models/professional_rating_stats.dart';
import '../providers/professional_rating_stats_provider.dart';

/// KPIs propios del profesional (recibidas como profesional), sin identidad de quién/cuándo — ver
/// `openspec/decisions.md`, backlog "ratings anónimo + KPIs". Primero resuelve el `id` interno del
/// propio perfil profesional (`myProfessionalProfileProvider`) — el endpoint de stats lo exige
/// como Int, no como `referenceId`.
class ProfessionalRatingStatsScreen extends ConsumerWidget {
  const ProfessionalRatingStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(myProfessionalProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.professionalRatingStatsTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(l10n.professionalRatingStatsError),
        ),
        data: (profile) => profile == null
            ? Center(child: Text(l10n.professionalRatingStatsError))
            : _StatsBody(professionalId: profile.id, l10n: l10n),
      ),
    );
  }
}

class _StatsBody extends ConsumerWidget {
  const _StatsBody({required this.professionalId, required this.l10n});

  final int professionalId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(
      professionalRatingStatsProvider(professionalId),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: AsyncStateView<ProfessionalRatingStats>(
        isLoading: statsAsync.isLoading,
        hasError: statsAsync.hasError,
        data: statsAsync.valueOrNull,
        errorMessage: l10n.professionalRatingStatsError,
        isEmpty: statsAsync.valueOrNull?.totalRatings == 0,
        emptyMessage: l10n.professionalRatingStatsEmpty,
        builder: (context, stats) => ListView(
          children: [
            TekoCard(
              child: ListTile(
                title: Text(l10n.professionalRatingStatsAverageLabel),
                trailing: Text(
                  stats.averageRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(
                  l10n.professionalRatingStatsTotalLabel(stats.totalRatings),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TekoCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.professionalRatingStatsDistributionLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    for (final stars in ['5', '4', '3', '2', '1'])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(width: 24, child: Text('$stars★')),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: stats.totalRatings == 0
                                    ? 0
                                    : (stats.ratingDistribution[stars] ?? 0) /
                                        stats.totalRatings,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${stats.ratingDistribution[stars] ?? 0}'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (stats.averageCriteria.isNotEmpty) ...[
              const SizedBox(height: 12),
              TekoCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.professionalRatingStatsCriteriaLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      for (final entry in stats.averageCriteria.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key),
                              Text(entry.value.toStringAsFixed(1)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
