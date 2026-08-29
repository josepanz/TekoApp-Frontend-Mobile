import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_badge.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../../contracts/providers/generate_contract_controller_provider.dart';
import '../models/budget_failure.dart';
import '../models/budget_line_item.dart';
import '../models/budget_option.dart';
import '../providers/budget_options_provider.dart';
import '../providers/select_budget_option_controller_provider.dart';

/// Comparación de opciones de presupuesto de una propuesta puntual (modo cliente) — ver
/// `openspec/changes/0009-multi-option-budgets.md`. El total de cada tarjeta es siempre el que
/// devolvió el backend, nunca un cálculo hecho acá.
class BudgetComparisonScreen extends ConsumerWidget {
  const BudgetComparisonScreen({
    super.key,
    required this.serviceId,
    required this.requestId,
  });

  final String serviceId;
  final String requestId;

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    String optionReferenceId,
  ) async {
    await ref
        .read(selectBudgetOptionControllerProvider.notifier)
        .select(serviceId, requestId, optionReferenceId);
    if (!context.mounted) return;

    final state = ref.read(selectBudgetOptionControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    if (!state.hasError) {
      // Presupuesto elegido → generar el contrato (Fase 0004) y navegar directo a su firma, en
      // vez de solo volver al detalle del servicio.
      final contract = await ref
          .read(generateContractControllerProvider.notifier)
          .generate(optionReferenceId);
      if (!context.mounted) return;
      if (contract != null) {
        context.pushReplacement('/contratos/${contract.referenceId}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.contractGenerateError)),
        );
        Navigator.of(context).pop(true);
      }
      return;
    }
    final message = switch (state.error) {
      BudgetConflictFailure() => l10n.budgetComparisonConflict,
      _ => l10n.budgetComparisonError,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final optionsAsync = ref.watch(
      budgetOptionsProvider((serviceId: serviceId, requestId: requestId)),
    );
    final options = optionsAsync.valueOrNull;
    final selectState = ref.watch(selectBudgetOptionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetComparisonTitle)),
      body: AsyncStateView<List<BudgetOption>>(
        isLoading: optionsAsync.isLoading,
        hasError: optionsAsync.hasError,
        data: options,
        isEmpty: options != null && options.isEmpty,
        errorMessage: l10n.budgetComparisonLoadError,
        emptyMessage: l10n.budgetComparisonEmpty,
        builder: (context, options) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: options.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final option = options[index];
            return _BudgetOptionCard(
              option: option,
              loading: selectState.isLoading,
              onSelect: () => _select(context, ref, option.referenceId),
            );
          },
        ),
      ),
    );
  }
}

class _BudgetOptionCard extends StatefulWidget {
  const _BudgetOptionCard({
    required this.option,
    required this.loading,
    required this.onSelect,
  });

  final BudgetOption option;
  final bool loading;
  final VoidCallback onSelect;

  @override
  State<_BudgetOptionCard> createState() => _BudgetOptionCardState();
}

class _BudgetOptionCardState extends State<_BudgetOptionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final option = widget.option;

    return TekoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  option.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (option.isSelected)
                TekoBadge(
                  label: l10n.budgetOptionSelectedBadge,
                  variant: TekoBadgeVariant.success,
                ),
            ],
          ),
          if (option.description != null) ...[
            const SizedBox(height: 4),
            Text(option.description!),
          ],
          const SizedBox(height: 8),
          Text(
            l10n.budgetOptionTotal(option.totalPrice.round()),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (option.estimatedHours != null)
            Text(
              l10n.budgetOptionEstimatedHours(option.estimatedHours!.round()),
            ),
          const SizedBox(height: 8),
          TextButton(
            key: Key('budget_option_toggle_details_${option.referenceId}'),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? l10n.budgetOptionHideDetails
                  : l10n.budgetOptionShowDetails,
            ),
          ),
          if (_expanded)
            for (final item in option.lineItems) _LineItemRow(item: item),
          const SizedBox(height: 8),
          if (!option.isSelected)
            TekoButton(
              key: Key('budget_option_select_${option.referenceId}'),
              label: l10n.budgetOptionSelectButton,
              loading: widget.loading,
              onPressed: widget.loading ? null : widget.onSelect,
            ),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item});

  final BudgetLineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.description} (${item.quantity})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            item.subtotal.round().toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
