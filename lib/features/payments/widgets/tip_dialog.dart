import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_input.dart';
import '../models/payment.dart';
import '../models/payment_failure.dart';
import '../models/tip.dart';
import '../models/tip_mode.dart';
import '../providers/create_tip_controller_provider.dart';
import '../providers/tip_config_provider.dart';

/// Abre el diálogo de propina para [payment] y, si se confirma, la envía y muestra el resultado.
/// Solo ofrece PERCENTAGE (chips de porcentaje sugerido) y FREE (monto libre) — `TipMode.fixed`
/// existe en el dominio/backend pero no tiene una config de montos preestablecidos todavía, ver
/// `openspec/decisions.md`.
Future<void> showTipDialog(
  BuildContext context,
  WidgetRef ref,
  Payment payment,
) async {
  final l10n = AppLocalizations.of(context)!;
  final config = await ref.read(tipConfigProvider.future);
  if (!context.mounted) return;

  final result = await showDialog<(TipMode, double)>(
    context: context,
    builder: (context) => _TipDialogContent(payment: payment, config: config),
  );
  if (result == null || !context.mounted) return;
  final (mode, value) = result;

  await ref.read(createTipControllerProvider.notifier).submit(
        payment.referenceId,
        mode: mode,
        percentage: mode == TipMode.percentage ? value : null,
        amount: mode == TipMode.percentage ? null : value,
      );
  if (!context.mounted) return;

  final state = ref.read(createTipControllerProvider);
  final message = switch (state.error) {
    null => l10n.paymentTipSuccess,
    PaymentValidationFailure(:final backendMessage) =>
      backendMessage ?? l10n.paymentTipError,
    PaymentConflictFailure(:final backendMessage) =>
      backendMessage ?? l10n.paymentTipError,
    _ => l10n.paymentTipError,
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _TipDialogContent extends StatefulWidget {
  const _TipDialogContent({required this.payment, required this.config});

  final Payment payment;
  final TipConfig config;

  @override
  State<_TipDialogContent> createState() => _TipDialogContentState();
}

class _TipDialogContentState extends State<_TipDialogContent> {
  int? _selectedPercentage;
  final _customAmountController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  double? get _customAmount => double.tryParse(
        _customAmountController.text.trim(),
      );

  bool get _canSubmit =>
      _selectedPercentage != null || (_customAmount ?? 0) > 0;

  void _selectPercentage(int percentage) {
    setState(() {
      _selectedPercentage = percentage;
      _customAmountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = widget.config;
    final suggestedPercentages = config.suggestedPercentages;
    final allowFreeAmount = config.allowFreeAmount;

    return AlertDialog(
      title: Text(l10n.paymentTipDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final percentage in suggestedPercentages)
                ChoiceChip(
                  key: Key('tip_percentage_chip_$percentage'),
                  label: Text('$percentage%'),
                  selected: _selectedPercentage == percentage,
                  onSelected: (_) => _selectPercentage(percentage),
                ),
            ],
          ),
          if (allowFreeAmount) ...[
            const SizedBox(height: 12),
            TekoInput(
              key: const Key('tip_custom_amount_field'),
              label: l10n.paymentTipCustomAmountLabel,
              controller: _customAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() => _selectedPercentage = null),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.paymentTipCancel),
        ),
        TextButton(
          key: const Key('tip_dialog_submit_button'),
          onPressed: _canSubmit
              ? () {
                  final selected = _selectedPercentage;
                  if (selected != null) {
                    Navigator.of(
                      context,
                    ).pop((TipMode.percentage, selected.toDouble()));
                  } else {
                    Navigator.of(
                      context,
                    ).pop((TipMode.free, _customAmount!));
                  }
                }
              : null,
          child: Text(l10n.paymentTipSubmit),
        ),
      ],
    );
  }
}
