// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "PromotionDetailResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'promotion.dart';

Promotion _$PromotionFromJson(Map<String, dynamic> json) => Promotion(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: PromotionType.fromJson(json['type'] as String),
      status: PromotionStatus.fromJson(json['status'] as String),
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      minimumAmount: (json['minimumAmount'] as num?)?.toDouble(),
      maximumDiscount: (json['maximumDiscount'] as num?)?.toDouble(),
      maxUsage: json['maxUsage'] as int,
      maxUsagePerUser: json['maxUsagePerUser'] as int,
      currentUsage: json['currentUsage'] as int,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validUntil: DateTime.parse(json['validUntil'] as String),
      allowedUserTypes:
          (json['allowedUserTypes'] as List<dynamic>).cast<String>(),
      specificUserIds: (json['specificUserIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      createdById: json['createdById'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastChangedAt: json['lastChangedAt'] == null
          ? null
          : DateTime.parse(json['lastChangedAt'] as String),
    );
