import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_input.dart';
import '../../promotions/models/promotion_failure.dart';
import '../../promotions/models/promotion_validation.dart';
import '../../promotions/providers/promotions_repository_provider.dart';
import '../../services/models/service.dart';
import '../../services/providers/service_detail_provider.dart';
import '../models/payment_failure.dart';
import '../models/payment_method.dart';
import '../providers/pay_service_controller_provider.dart';
import '../providers/payment_methods_provider.dart';
import 'payment_method_labels.dart';

/// Pagar un servicio propio ya `COMPLETED` — ver
/// `openspec/changes/0004-payments-and-ratings.md`.
class PayServiceScreen extends ConsumerWidget {
  const PayServiceScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payServiceTitle)),
      body: switch (serviceAsync) {
        AsyncData(:final value) => _PayServiceBody(service: value),
        AsyncError() => Center(child: Text(l10n.serviceDetailError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _PayServiceBody extends ConsumerStatefulWidget {
  const _PayServiceBody({required this.service});

  final Service service;

  @override
  ConsumerState<_PayServiceBody> createState() => _PayServiceBodyState();
}

class _PayServiceBodyState extends ConsumerState<_PayServiceBody> {
  final _promoCodeController = TextEditingController();
  PaymentMethod? _selectedMethod;
  PromotionValidation? _promoPreview;
  String? _promoMessage;
  bool _validatingPromo = false;

  double get _serviceAmount =>
      widget.service.finalAmount ?? widget.service.totalAmount ?? 0;

  /// Mismo criterio que `PaymentsService.assertPaymentMethodNotExpired` del backend
  /// (`method.expiresAt <= now`) — un método sin `expiresAt` nunca vence.
  bool _isExpired(PaymentMethod method) {
    final expiresAt = method.expiresAt;
    return expiresAt != null && !expiresAt.isAfter(DateTime.now());
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _validatePromo() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _validatingPromo = true;
      _promoMessage = null;
    });
    try {
      final result = await ref
          .read(promotionsRepositoryProvider)
          .validate(code: code, serviceAmount: _serviceAmount);
      setState(() {
        _promoPreview = result.isValid ? result : null;
        _promoMessage = result.isValid ? null : result.message;
      });
    } on PromotionFailure {
      if (!mounted) return;
      setState(() {
        _promoPreview = null;
        _promoMessage = AppLocalizations.of(context)!.payServiceError;
      });
    } finally {
      if (mounted) setState(() => _validatingPromo = false);
    }
  }

  Future<void> _confirm() async {
    final method = _selectedMethod;
    if (method == null) return;

    await ref.read(payServiceControllerProvider.notifier).submit(
          professionalReferenceId: widget.service.professional!.referenceId,
          serviceId: widget.service.referenceId,
          serviceAmount: _serviceAmount,
          method: method,
          promotionCode:
              _promoPreview != null ? _promoCodeController.text.trim() : null,
        );
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(payServiceControllerProvider);
    if (!state.hasError) {
      context.go('/pagos/historial');
      return;
    }
    final message = switch (state.error) {
      PromotionRejected(:final message) => message ?? l10n.payServiceError,
      PaymentMethodExpiredFailure(:final backendMessage) =>
        backendMessage ?? l10n.payServiceMethodExpiredError,
      PaymentValidationFailure(:final backendMessage) =>
        backendMessage ?? l10n.payServiceError,
      PaymentConflictFailure(:final backendMessage) =>
        backendMessage ?? l10n.payServiceError,
      _ => l10n.payServiceError,
    };
    if (state.error is PaymentMethodExpiredFailure) {
      // Venció entre que se pintó el selector y se confirmó el pago (el backend es la fuente de
      // verdad) — se limpia la selección para forzar elegir otro método; el próximo build ya lo
      // muestra deshabilitado en el dropdown con la fecha actual.
      setState(() => _selectedMethod = null);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final methodsAsync = ref.watch(paymentMethodsProvider);
    final methods = methodsAsync.valueOrNull ?? const <PaymentMethod>[];
    final submitState = ref.watch(payServiceControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.paymentAmountLabel(_serviceAmount.round()),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (_promoPreview != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.payServiceDiscountApplied(
                _promoPreview!.discountAmount.round(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TekoInput(
                  key: const Key('pay_service_promo_code_field'),
                  label: l10n.payServicePromoCodeLabel,
                  controller: _promoCodeController,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TekoButton(
                  key: const Key('pay_service_validate_promo_button'),
                  label: l10n.payServiceValidatePromoButton,
                  loading: _validatingPromo,
                  onPressed: _validatingPromo ? null : _validatePromo,
                ),
              ),
            ],
          ),
          if (_promoMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _promoMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          if (methods.isEmpty) ...[
            Text(l10n.payServiceNoMethodsMessage),
            const SizedBox(height: 8),
            TekoButton(
              key: const Key('pay_service_add_method_link'),
              label: l10n.payServiceAddMethodLink,
              variant: TekoButtonVariant.outline,
              onPressed: () => context.push('/pagos/metodos/nuevo'),
            ),
          ] else ...[
            DropdownButtonFormField<PaymentMethod>(
              key: const Key('pay_service_method_field'),
              initialValue: _selectedMethod,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.payServiceMethodLabel,
                helperText: methods.any(_isExpired)
                    ? l10n.payServiceMethodExpiredHint
                    : null,
                helperMaxLines: 2,
              ),
              items: [
                for (final method in methods)
                  DropdownMenuItem(
                    key: Key('pay_service_method_option_${method.referenceId}'),
                    value: method,
                    enabled: !_isExpired(method),
                    child: Text(
                      _isExpired(method)
                          ? '${method.name} · '
                              '${paymentMethodTypeLabel(l10n, method.type)} · '
                              '${l10n.payServiceMethodExpiredLabel}'
                          : '${method.name} · '
                              '${paymentMethodTypeLabel(l10n, method.type)}',
                      overflow: TextOverflow.ellipsis,
                      style: _isExpired(method)
                          ? TextStyle(
                              color: Theme.of(context).disabledColor,
                            )
                          : null,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedMethod = value),
            ),
          ],
          if (submitState.hasError) ...[
            const SizedBox(height: 12),
            Text(
              l10n.payServiceError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          TekoButton(
            key: const Key('pay_service_confirm_button'),
            label: l10n.payServiceConfirmButton,
            loading: submitState.isLoading,
            onPressed: (submitState.isLoading || _selectedMethod == null)
                ? null
                : _confirm,
          ),
        ],
      ),
    );
  }
}
