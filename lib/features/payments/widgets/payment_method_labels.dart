import '../../../l10n/app_localizations.dart';
import '../models/payment_method.dart';

/// Traduce los enums de tipo/proveedor a etiquetas legibles — un solo lugar para mantenerlas
/// consistentes entre el listado y el formulario de alta (mismo criterio que
/// `ServiceStatusBadge`).
String paymentMethodTypeLabel(AppLocalizations l10n, PaymentMethodType type) {
  return switch (type) {
    PaymentMethodType.cash => l10n.paymentMethodTypeCash,
    PaymentMethodType.creditCard => l10n.paymentMethodTypeCreditCard,
    PaymentMethodType.debitCard => l10n.paymentMethodTypeDebitCard,
    PaymentMethodType.prepaidCard => l10n.paymentMethodTypePrepaidCard,
    PaymentMethodType.qr => l10n.paymentMethodTypeQr,
    PaymentMethodType.link => l10n.paymentMethodTypeLink,
    PaymentMethodType.transfer => l10n.paymentMethodTypeTransfer,
    PaymentMethodType.wallet => l10n.paymentMethodTypeWallet,
    PaymentMethodType.mobileWallet => l10n.paymentMethodTypeMobileWallet,
    PaymentMethodType.crypto => l10n.paymentMethodTypeCrypto,
  };
}

String paymentProviderLabel(
  AppLocalizations l10n,
  PaymentProviderType provider,
) {
  return switch (provider) {
    PaymentProviderType.stripe => l10n.paymentProviderStripe,
    PaymentProviderType.bancard => l10n.paymentProviderBancard,
    PaymentProviderType.infonet => l10n.paymentProviderInfonet,
    PaymentProviderType.paypal => l10n.paymentProviderPaypal,
    PaymentProviderType.mercadoPago => l10n.paymentProviderMercadoPago,
    PaymentProviderType.rapipago => l10n.paymentProviderRapipago,
    PaymentProviderType.pagofacil => l10n.paymentProviderPagofacil,
    PaymentProviderType.cash => l10n.paymentProviderCash,
    PaymentProviderType.dinelco => l10n.paymentProviderDinelco,
    PaymentProviderType.bepsa => l10n.paymentProviderBepsa,
  };
}
