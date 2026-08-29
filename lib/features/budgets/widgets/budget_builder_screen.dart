import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../../../shared/widgets/teko_input.dart';
import '../models/budget_failure.dart';
import '../models/budget_line_item_type.dart';
import '../models/budget_option.dart';
import '../models/material_catalog_item.dart';
import '../providers/material_catalog_provider.dart';
import '../providers/submit_budget_options_controller_provider.dart';

const _freeItemValue = '__free__';

/// Armado de presupuesto multi-opción del profesional — se abre inmediatamente después de
/// proponerse a un `Service` (ver `ProposeOnServiceController.submit`). Reemplaza el
/// `proposedPrice` único de antes: el precio ahora surge de la suma de line items de cada opción,
/// siempre recalculado server-side al enviar (nunca se manda el total calculado acá como verdad).
class BudgetBuilderScreen extends ConsumerStatefulWidget {
  const BudgetBuilderScreen({
    super.key,
    required this.serviceId,
    required this.requestId,
    required this.categoryId,
  });

  final String serviceId;
  final String requestId;
  final int categoryId;

  @override
  ConsumerState<BudgetBuilderScreen> createState() =>
      _BudgetBuilderScreenState();
}

class _BudgetBuilderScreenState extends ConsumerState<BudgetBuilderScreen> {
  final List<BudgetOptionDraft> _options = [
    BudgetOptionDraft(label: 'Estándar'),
  ];

  void _addOption() {
    setState(
      () => _options.add(BudgetOptionDraft(label: 'Opción ${_options.length + 1}')),
    );
  }

  void _removeOption(int index) {
    setState(() => _options.removeAt(index));
  }

  Future<void> _submit() async {
    await ref
        .read(submitBudgetOptionsControllerProvider.notifier)
        .submit(widget.serviceId, widget.requestId, _options);
    if (!mounted) return;

    final state = ref.read(submitBudgetOptionsControllerProvider);
    if (!state.hasError) {
      Navigator.of(context).pop(true);
    }
  }

  String _errorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      BudgetValidationFailure(:final backendMessage) =>
        backendMessage ?? l10n.budgetBuilderError,
      BudgetConflictFailure() => l10n.budgetBuilderConflict,
      _ => l10n.budgetBuilderError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalogAsync = ref.watch(materialCatalogProvider(widget.categoryId));
    final submitState = ref.watch(submitBudgetOptionsControllerProvider);
    final canSubmit = _options.every(
      (option) =>
          option.label.trim().isNotEmpty &&
          option.lineItems.isNotEmpty &&
          option.lineItems.every(
            (item) => item.description.trim().isNotEmpty && item.quantity > 0,
          ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetBuilderTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < _options.length; i++) ...[
            _BudgetOptionEditor(
              draft: _options[i],
              catalog: catalogAsync.valueOrNull ?? const [],
              onChanged: () => setState(() {}),
              onRemove: _options.length > 1 ? () => _removeOption(i) : null,
            ),
            const SizedBox(height: 16),
          ],
          TekoButton(
            key: const Key('budget_builder_add_option_button'),
            label: l10n.budgetBuilderAddOption,
            variant: TekoButtonVariant.outline,
            onPressed: _addOption,
          ),
          const SizedBox(height: 24),
          if (submitState.hasError) ...[
            Text(
              _errorMessage(l10n, submitState.error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          TekoButton(
            key: const Key('budget_builder_submit_button'),
            label: l10n.budgetBuilderSubmitButton,
            loading: submitState.isLoading,
            onPressed: (!canSubmit || submitState.isLoading) ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _BudgetOptionEditor extends StatelessWidget {
  const _BudgetOptionEditor({
    required this.draft,
    required this.catalog,
    required this.onChanged,
    this.onRemove,
  });

  final BudgetOptionDraft draft;
  final List<MaterialCatalogItem> catalog;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  void _addLineItem() {
    draft.lineItems.add(
      BudgetLineItemDraft(
        itemType: BudgetLineItemType.material,
        description: '',
        quantity: 1,
        unitPrice: 0,
      ),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TekoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TekoInput(
                  key: const Key('budget_option_label_input'),
                  label: l10n.budgetOptionLabel,
                  initialValue: draft.label,
                  onChanged: (value) {
                    draft.label = value;
                    onChanged();
                  },
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < draft.lineItems.length; i++) ...[
            _LineItemEditor(
              draft: draft.lineItems[i],
              catalog: catalog,
              onChanged: onChanged,
              onRemove: () {
                draft.lineItems.removeAt(i);
                onChanged();
              },
            ),
            const SizedBox(height: 8),
          ],
          TekoButton(
            key: Key('budget_option_add_line_item_${draft.label}'),
            label: l10n.budgetOptionAddLineItem,
            variant: TekoButtonVariant.ghost,
            size: TekoButtonSize.sm,
            onPressed: _addLineItem,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.budgetOptionTotal(draft.totalPrice.round()),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _LineItemEditor extends StatelessWidget {
  const _LineItemEditor({
    required this.draft,
    required this.catalog,
    required this.onChanged,
    required this.onRemove,
  });

  final BudgetLineItemDraft draft;
  final List<MaterialCatalogItem> catalog;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  void _onCatalogItemSelected(String? value) {
    if (value == null || value == _freeItemValue) {
      draft.catalogItemReferenceId = null;
      onChanged();
      return;
    }
    final item = catalog.firstWhere((item) => item.referenceId == value);
    draft
      ..catalogItemReferenceId = item.referenceId
      ..description = item.name
      ..unitPrice = item.defaultPrice;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              if (catalog.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: draft.catalogItemReferenceId ?? _freeItemValue,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.lineItemCatalogItem),
                  items: [
                    DropdownMenuItem(
                      value: _freeItemValue,
                      child: Text(l10n.lineItemFreeItem),
                    ),
                    for (final item in catalog)
                      DropdownMenuItem(
                        value: item.referenceId,
                        child: Text(item.name),
                      ),
                  ],
                  onChanged: _onCatalogItemSelected,
                ),
              const SizedBox(height: 4),
              TekoInput(
                key: Key('line_item_description_${draft.hashCode}'),
                label: l10n.lineItemDescription,
                initialValue: draft.description,
                onChanged: (value) => draft.description = value,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: TekoInput(
            key: Key('line_item_quantity_${draft.hashCode}'),
            label: l10n.lineItemQuantity,
            initialValue: draft.quantity.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              draft.quantity = double.tryParse(value) ?? draft.quantity;
              onChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: TekoInput(
            key: Key('line_item_unit_price_${draft.hashCode}'),
            label: l10n.lineItemUnitPrice,
            initialValue: draft.unitPrice.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              draft.unitPrice = double.tryParse(value) ?? draft.unitPrice;
              onChanged();
            },
          ),
        ),
        IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
      ],
    );
  }
}
