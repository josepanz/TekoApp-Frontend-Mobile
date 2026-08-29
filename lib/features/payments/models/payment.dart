import 'payment_method.dart';
import 'payment_status.dart';
import 'tip.dart';

/// `Payments` — desde 0008-id-referenceid-standardization el backend expone `id` (Int interno,
/// secuencial) y `referenceId` (UUID) por separado (ver `openspec/decisions.md`). `id` sirve SOLO
/// para ordenamiento, nunca para navegar/consultar/rutear — usar siempre `referenceId` para eso.
/// `userId`/`professionalId` siguen siendo el Int interno crudo (mismo patrón ya documentado en
/// `Service`). `refundDetails.refundedAmount` (si existe) es el acumulado ya reembolsado — no hay
/// un campo `availableForRefund` explícito, se calcula con [amountAvailableForRefund].
class Payment {
  const Payment({
    required this.id,
    required this.referenceId,
    required this.userId,
    required this.professionalId,
    required this.serviceId,
    required this.amount,
    required this.currencyCode,
    required this.fee,
    required this.tax,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentProvider,
    required this.transactionId,
    required this.createdAt,
    this.description,
    this.refundDetails,
    this.tip,
  });

  /// Int interno secuencial — solo para ordenamiento, nunca para navegar/consultar/rutear.
  final int id;

  /// UUID público — la clave real para navegación/deep-linking y lookups por API.
  final String referenceId;
  final int userId;
  final int professionalId;
  final String serviceId;
  final double amount;
  final String currencyCode;
  final double fee;
  final double tax;
  final double totalAmount;
  final PaymentStatus status;
  final PaymentMethodType paymentMethod;
  final PaymentProviderType paymentProvider;
  final String transactionId;
  final DateTime createdAt;
  final String? description;
  final Map<String, dynamic>? refundDetails;

  /// Propina dejada para este pago, si existe — nunca fusionada a [totalAmount].
  final Tip? tip;

  /// Monto ya reembolsado (acumulado de reembolsos parciales), 0 si no hubo ninguno.
  double get refundedAmount {
    final value = refundDetails?['refundedAmount'];
    return value is num ? value.toDouble() : 0;
  }

  /// Monto disponible para un nuevo reembolso — `totalAmount` menos lo ya reembolsado.
  double get amountAvailableForRefund => totalAmount - refundedAmount;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      userId: json['userId'] as int,
      professionalId: json['professionalId'] as int,
      serviceId: json['serviceId'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      fee: (json['fee'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: PaymentStatus.fromJson(json['status'] as String),
      paymentMethod:
          PaymentMethodType.fromJson(json['paymentMethod'] as String),
      paymentProvider: PaymentProviderType.fromJson(
        json['paymentProvider'] as String,
      ),
      transactionId: json['transactionId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String?,
      refundDetails: json['refundDetails'] as Map<String, dynamic>?,
      tip: json['tip'] != null
          ? Tip.fromJson(json['tip'] as Map<String, dynamic>)
          : null,
    );
  }
}
