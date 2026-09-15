// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "PaymentDetailResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'payment.dart';

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      userId: json['userId'] as int,
      professionalId: json['professionalId'] as int,
      serviceId: json['serviceId'] as String,
      amount: (json['amount'] as num).toDouble(),
      tip: json['tip'] == null
          ? null
          : Tip.fromJson(json['tip'] as Map<String, dynamic>),
      currencyCode: json['currencyCode'] as String,
      fee: (json['fee'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: PaymentStatus.fromJson(json['status'] as String),
      paymentMethod:
          PaymentMethodType.fromJson(json['paymentMethod'] as String),
      paymentProvider:
          PaymentProviderType.fromJson(json['paymentProvider'] as String),
      transactionId: json['transactionId'] as String,
      externalTransactionId: json['externalTransactionId'] as String?,
      description: json['description'] as String?,
      paymentDetails: json['paymentDetails'] as Map<String, dynamic>?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      failedAt: json['failedAt'] == null
          ? null
          : DateTime.parse(json['failedAt'] as String),
      paidAt: json['paidAt'] == null
          ? null
          : DateTime.parse(json['paidAt'] as String),
      failureReason: json['failureReason'] as String?,
      refundDetails: json['refundDetails'] as Map<String, dynamic>?,
      platformFee: (json['platformFee'] as num).toDouble(),
      professionalNetAmount:
          (json['professionalNetAmount'] as num?)?.toDouble(),
      isRecurring: json['isRecurring'] as bool,
      recurringInterval: json['recurringInterval'] as String?,
      nextPaymentDate: json['nextPaymentDate'] == null
          ? null
          : DateTime.parse(json['nextPaymentDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastChangedAt: json['lastChangedAt'] == null
          ? null
          : DateTime.parse(json['lastChangedAt'] as String),
    );
