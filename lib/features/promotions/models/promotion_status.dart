/// `Promotions.status` (`prisma/schema.prisma`, enum `PromotionStatus` del backend). El backend
/// ya valida vigencia/agotamiento server-side (ver `PromotionValidation.isValid`/`message`) — este
/// campo es informativo sobre el detalle de una promoción ya validada, no reemplaza esa
/// validación.
enum PromotionStatus {
  active,
  inactive,
  expired,
  depleted;

  factory PromotionStatus.fromJson(String value) {
    return switch (value) {
      'ACTIVE' => PromotionStatus.active,
      'INACTIVE' => PromotionStatus.inactive,
      'EXPIRED' => PromotionStatus.expired,
      'DEPLETED' => PromotionStatus.depleted,
      _ => throw ArgumentError('PromotionStatus desconocido: $value'),
    };
  }
}
