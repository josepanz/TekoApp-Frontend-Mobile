import 'payment_method.dart';
import 'payment_status.dart';
import 'tip.dart';

part 'payment.g.dart';

/// `Payments` — desde 0008-id-referenceid-standardization el backend expone `id` (Int interno,
/// secuencial) y `referenceId` (UUID) por separado (ver `openspec/decisions.md`). `id` sirve SOLO
/// para ordenamiento, nunca para navegar/consultar/rutear — usar siempre `referenceId` para eso.
/// `userId`/`professionalId` siguen siendo el Int interno crudo (mismo patrón ya documentado en
/// `Service`). `refundDetails.refundedAmount` (si existe) es el acumulado ya reembolsado — no hay
/// un campo `availableForRefund` explícito, se calcula con [amountAvailableForRefund].
///
/// Campos agregados en M-05 (`externalTransactionId`, `paymentDetails`, `metadata`,
/// `processedAt`/`paidAt`/`failedAt`, `failureReason`, `platformFee`, `professionalNetAmount`,
/// `isRecurring`/`recurringInterval`/`nextPaymentDate`, `lastChangedAt`) — el backend ya los
/// devuelve (`PaymentDetailResponseDTO`), el modelo los descartaba en silencio. Ninguno tiene
/// consumidor en la UI todavía — expuestos para que una pantalla de recibo/disputa no tenga que
/// volver a tocar el modelo primero.
///
/// `professionalNetAmount` — a diferencia de lo que decía este mismo comentario antes de M-05, D-03
/// (`TekoApp-Backend`) ya está resuelto: el backend lo calcula (`amount - platformFee - tax`,
/// ajustado por reembolsos) en vez de devolver siempre `null` — verificado contra
/// `payments-response.helper.ts`/`professional-net-amount.helper.ts` el 2026-09-06. Sigue
/// nullable porque el DTO lo declara opcional, no porque el backend no lo escriba.
///
/// `fromJson` está generado desde el schema real de `PaymentDetailResponseDTO` (ver M-04,
/// `tool/openapi_codegen/generate_model.dart` y `payment.g.dart`) — validado contra
/// `--openapi-url` de un backend corriendo, no contra un fixture a mano. No aparecieron campos
/// nuevos: M-05 ya había expuesto todo lo que el DTO real devuelve.
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
    required this.platformFee,
    required this.isRecurring,
    required this.createdAt,
    this.description,
    this.refundDetails,
    this.tip,
    this.externalTransactionId,
    this.paymentDetails,
    this.metadata,
    this.processedAt,
    this.paidAt,
    this.failedAt,
    this.failureReason,
    this.professionalNetAmount,
    this.recurringInterval,
    this.nextPaymentDate,
    this.lastChangedAt,
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

  /// Comisión de la plataforma ya calculada y persistida al crear el pago — ver
  /// `professionalNetAmount`.
  final double platformFee;
  final bool isRecurring;
  final DateTime createdAt;
  final String? description;
  final Map<String, dynamic>? refundDetails;

  /// Propina dejada para este pago, si existe — nunca fusionada a [totalAmount].
  final Tip? tip;

  /// ID de transacción del proveedor externo (Stripe, etc.) — distinto de [transactionId].
  final String? externalTransactionId;
  final Map<String, dynamic>? paymentDetails;
  final Map<String, dynamic>? metadata;
  final DateTime? processedAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final String? failureReason;

  /// Monto neto del profesional (`amount - platformFee - tax`, ajustado por reembolsos) — ver el
  /// docstring de la clase sobre D-03.
  final double? professionalNetAmount;
  final String? recurringInterval;
  final DateTime? nextPaymentDate;
  final DateTime? lastChangedAt;

  /// Monto ya reembolsado (acumulado de reembolsos parciales), 0 si no hubo ninguno.
  double get refundedAmount {
    final value = refundDetails?['refundedAmount'];
    return value is num ? value.toDouble() : 0;
  }

  /// Monto disponible para un nuevo reembolso — `totalAmount` menos lo ya reembolsado.
  double get amountAvailableForRefund => totalAmount - refundedAmount;

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
}
