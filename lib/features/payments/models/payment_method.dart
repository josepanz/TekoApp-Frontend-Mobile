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

/// `PaymentMethodEntity` — desde 0008-id-referenceid-standardization el backend expone `id` (Int
/// interno, secuencial) y `referenceId` (UUID) por separado (ver `openspec/decisions.md`). `id`
/// sirve SOLO para ordenamiento, nunca para navegar/consultar/rutear — usar siempre `referenceId`
/// para eso. Sin tokenización real de proveedor en esta fase: `details` es lo que el usuario
/// ingresó a mano (ej. últimos 4 dígitos).
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.referenceId,
    required this.userId,
    required this.name,
    required this.type,
    required this.provider,
    required this.isDefault,
    required this.isActive,
    required this.details,
    this.externalId,
    this.metadata,
    this.lastUsedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Int interno secuencial — solo para ordenamiento, nunca para navegar/consultar/rutear.
  final int id;

  /// UUID público — la clave real para navegación/deep-linking y lookups por API.
  final String referenceId;

  /// Dueño de la cuenta — sin consumidor en la UI todavía (la pantalla ya filtra "mis métodos"
  /// contra el usuario autenticado del lado del backend), se expone igual que el resto de campos
  /// agregados en M-04 para que no se vuelva a perder si algún consumidor lo necesita.
  final int userId;
  final String name;
  final PaymentMethodType type;
  final PaymentProviderType provider;
  final bool isDefault;
  final bool isActive;
  final Map<String, dynamic> details;
  final String? externalId;
  final Map<String, dynamic>? metadata;
  final DateTime? lastUsedAt;

  /// Vencimiento (ej. tarjetas) — se muestra en `payment_methods_screen.dart` cuando no es
  /// `null`. Ambigüedad pendiente (ver reporte): no se agregó lógica para deshabilitar/filtrar un
  /// método ya vencido en la selección de `pay_service_screen.dart` — es una decisión de negocio
  /// (¿el backend igual permite pagar con un método vencido, o rechaza y esto queda solo como
  /// aviso visual?) que no se decidió acá.
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      userId: json['userId'] as int,
      name: json['name'] as String,
      type: PaymentMethodType.fromJson(json['type'] as String),
      provider: PaymentProviderType.fromJson(json['provider'] as String),
      isDefault: json['isDefault'] as bool,
      isActive: json['isActive'] as bool,
      details: (json['details'] as Map<String, dynamic>?) ?? const {},
      externalId: json['externalId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      lastUsedAt: json['lastUsedAt'] == null
          ? null
          : DateTime.parse(json['lastUsedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
