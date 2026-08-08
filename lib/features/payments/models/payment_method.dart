/// Tipo del método de pago — mismo enum `PaymentMethod` de `TekoApp-Backend`
/// (`prisma/schema.prisma`).
enum PaymentMethodType {
  cash,
  creditCard,
  debitCard,
  prepaidCard,
  qr,
  link,
  transfer,
  wallet,
  mobileWallet,
  crypto;

  factory PaymentMethodType.fromJson(String value) {
    return switch (value) {
      'CASH' => PaymentMethodType.cash,
      'CREDIT_CARD' => PaymentMethodType.creditCard,
      'DEBIT_CARD' => PaymentMethodType.debitCard,
      'PREPAID_CARD' => PaymentMethodType.prepaidCard,
      'QR' => PaymentMethodType.qr,
      'LINK' => PaymentMethodType.link,
      'TRANSFER' => PaymentMethodType.transfer,
      'WALLET' => PaymentMethodType.wallet,
      'MOBILE_WALLET' => PaymentMethodType.mobileWallet,
      'CRYPTO' => PaymentMethodType.crypto,
      _ => throw ArgumentError('PaymentMethodType desconocido: $value'),
    };
  }

  String toJson() {
    return switch (this) {
      PaymentMethodType.cash => 'CASH',
      PaymentMethodType.creditCard => 'CREDIT_CARD',
      PaymentMethodType.debitCard => 'DEBIT_CARD',
      PaymentMethodType.prepaidCard => 'PREPAID_CARD',
      PaymentMethodType.qr => 'QR',
      PaymentMethodType.link => 'LINK',
      PaymentMethodType.transfer => 'TRANSFER',
      PaymentMethodType.wallet => 'WALLET',
      PaymentMethodType.mobileWallet => 'MOBILE_WALLET',
      PaymentMethodType.crypto => 'CRYPTO',
    };
  }
}

/// Proveedor de pagos — mismo enum `PaymentProvider` de `TekoApp-Backend`.
enum PaymentProviderType {
  stripe,
  bancard,
  infonet,
  paypal,
  mercadoPago,
  rapipago,
  pagofacil,
  cash,
  dinelco,
  bepsa;

  factory PaymentProviderType.fromJson(String value) {
    return switch (value) {
      'STRIPE' => PaymentProviderType.stripe,
      'BANCARD' => PaymentProviderType.bancard,
      'INFONET' => PaymentProviderType.infonet,
      'PAYPAL' => PaymentProviderType.paypal,
      'MERCADO_PAGO' => PaymentProviderType.mercadoPago,
      'RAPIPAGO' => PaymentProviderType.rapipago,
      'PAGOFACIL' => PaymentProviderType.pagofacil,
      'CASH' => PaymentProviderType.cash,
      'DINELCO' => PaymentProviderType.dinelco,
      'BEPSA' => PaymentProviderType.bepsa,
      _ => throw ArgumentError('PaymentProviderType desconocido: $value'),
    };
  }

  String toJson() {
    return switch (this) {
      PaymentProviderType.stripe => 'STRIPE',
      PaymentProviderType.bancard => 'BANCARD',
      PaymentProviderType.infonet => 'INFONET',
      PaymentProviderType.paypal => 'PAYPAL',
      PaymentProviderType.mercadoPago => 'MERCADO_PAGO',
      PaymentProviderType.rapipago => 'RAPIPAGO',
      PaymentProviderType.pagofacil => 'PAGOFACIL',
      PaymentProviderType.cash => 'CASH',
      PaymentProviderType.dinelco => 'DINELCO',
      PaymentProviderType.bepsa => 'BEPSA',
    };
  }
}

/// `PaymentMethodEntity` — el `id` ya es el `referenceId` (UUID) expuesto por
/// `mapPaymentMethodToResponse` (backend), sin tokenización real de proveedor en esta fase (ver
/// `openspec/decisions.md`): `details` es lo que el usuario ingresó a mano (ej. últimos 4 dígitos).
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    required this.provider,
    required this.isDefault,
    required this.isActive,
    required this.details,
    this.externalId,
  });

  final String id;
  final String name;
  final PaymentMethodType type;
  final PaymentProviderType provider;
  final bool isDefault;
  final bool isActive;
  final Map<String, dynamic> details;
  final String? externalId;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PaymentMethodType.fromJson(json['type'] as String),
      provider: PaymentProviderType.fromJson(json['provider'] as String),
      isDefault: json['isDefault'] as bool,
      isActive: json['isActive'] as bool,
      details: (json['details'] as Map<String, dynamic>?) ?? const {},
      externalId: json['externalId'] as String?,
    );
  }
}
