import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_input.dart';
import '../models/payment_method.dart';
import '../providers/payment_method_controller_provider.dart';
import 'payment_method_labels.dart';

/// Alta de un método de pago propio — sin tokenización real de proveedor en esta fase (ver
/// `openspec/decisions.md`): `details` es lo que el usuario ingresa a mano.
class AddPaymentMethodScreen extends ConsumerStatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  ConsumerState<AddPaymentMethodScreen> createState() =>
      _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState
    extends ConsumerState<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();

  PaymentMethodType? _selectedType;
  PaymentProviderType? _selectedProvider;

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    final detail = _detailController.text.trim();
    ref.read(paymentMethodControllerProvider.notifier).create(
          name: _nameController.text.trim(),
          type: _selectedType!,
          provider: _selectedProvider!,
          details: detail.isEmpty ? null : {'detail': detail},
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final submitState = ref.watch(paymentMethodControllerProvider);

    ref.listen(paymentMethodControllerProvider, (previous, next) {
      // `AsyncNotifier<void>` conserva `hasValue=true` en error una vez que tuvo un valor previo
      // — `!hasError` es la señal correcta de "terminó bien" (ver `request_service_screen.dart`).
      if (previous?.isLoading == true && !next.hasError) {
        Navigator.of(context).maybePop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentMethodFormTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TekoInput(
                key: const Key('payment_method_name_field'),
                label: l10n.paymentMethodNameLabel,
                controller: _nameController,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.paymentMethodNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethodType>(
                key: const Key('payment_method_type_field'),
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: l10n.paymentMethodTypeLabel,
                ),
                items: [
                  for (final type in PaymentMethodType.values)
                    DropdownMenuItem(
                      value: type,
                      child: Text(paymentMethodTypeLabel(l10n, type)),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (value) =>
                    value == null ? l10n.paymentMethodTypeRequired : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentProviderType>(
                key: const Key('payment_method_provider_field'),
                initialValue: _selectedProvider,
                decoration: InputDecoration(
                  labelText: l10n.paymentMethodProviderLabel,
                ),
                items: [
                  for (final provider in PaymentProviderType.values)
                    DropdownMenuItem(
                      value: provider,
                      child: Text(paymentProviderLabel(l10n, provider)),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedProvider = value),
                validator: (value) =>
                    value == null ? l10n.paymentMethodProviderRequired : null,
              ),
              const SizedBox(height: 12),
              TekoInput(
                key: const Key('payment_method_detail_field'),
                label: l10n.paymentMethodDetailLabel,
                controller: _detailController,
              ),
              if (submitState.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.paymentMethodGenericError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              TekoButton(
                key: const Key('payment_method_form_submit_button'),
                label: l10n.paymentMethodFormSubmit,
                loading: submitState.isLoading,
                onPressed: submitState.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
