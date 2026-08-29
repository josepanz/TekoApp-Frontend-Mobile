import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_badge.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/contract.dart';
import '../models/contract_status.dart';
import '../providers/my_contracts_provider.dart';

/// Listado de contratos propios (cliente y profesional ven los suyos) — `GET /contracts`, ver
/// `openspec/decisions.md` (endpoint agregado durante la implementación de esta pantalla).
class MyContractsScreen extends ConsumerWidget {
  const MyContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contractsAsync = ref.watch(myContractsProvider);
    final contracts = contractsAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myContractsScreenTitle)),
      body: AsyncStateView<List<MyContractSummary>>(
        isLoading: contractsAsync.isLoading,
        hasError: contractsAsync.hasError,
        data: contracts,
        isEmpty: contracts != null && contracts.isEmpty,
        errorMessage: l10n.myContractsLoadError,
        emptyMessage: l10n.myContractsEmpty,
        builder: (context, contracts) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: contracts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ContractTile(
            contract: contracts[index],
          ),
        ),
      ),
    );
  }
}

class _ContractTile extends StatelessWidget {
  const _ContractTile({required this.contract});

  final MyContractSummary contract;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, variant) = switch (contract.status) {
      ContractStatus.signed => (
          l10n.contractStatusSigned,
          TekoBadgeVariant.success,
        ),
      _ => (l10n.contractStatusPendingYourSignature, TekoBadgeVariant.warning),
    };

    return InkWell(
      key: Key('my_contract_tile_${contract.referenceId}'),
      onTap: () => context.push('/contratos/${contract.referenceId}'),
      child: TekoCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                contract.serviceTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TekoBadge(label: label, variant: variant),
          ],
        ),
      ),
    );
  }
}
