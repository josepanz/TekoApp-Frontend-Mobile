import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/user_rating_stats.dart';
import '../providers/my_rating_stats_provider.dart';

/// KPIs propios del cliente (dadas/recibidas), sin identidad de quién/cuándo — ver
/// `openspec/decisions.md`, backlog "ratings anónimo + KPIs".
class MyRatingStatsScreen extends ConsumerWidget {
  const MyRatingStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(myRatingStatsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myRatingStatsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: AsyncStateView<UserRatingStats>(
          isLoading: statsAsync.isLoading,
          hasError: statsAsync.hasError,
          data: statsAsync.valueOrNull,
          errorMessage: l10n.myRatingStatsError,
          builder: (context, stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TekoCard(
                child: ListTile(
                  title: Text(l10n.myRatingStatsGivenLabel),
                  trailing: Text(
                    '${stats.givenRatings}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    '${l10n.myRatingStatsAverageGivenLabel}: '
                    '${stats.averageGivenRating.toStringAsFixed(1)}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TekoCard(
                child: ListTile(
                  title: Text(l10n.myRatingStatsReceivedLabel),
                  trailing: Text(
                    '${stats.receivedRatings}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    '${l10n.myRatingStatsAverageReceivedLabel}: '
                    '${stats.averageReceivedRating.toStringAsFixed(1)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
