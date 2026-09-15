/// `Promotions.type` (`prisma/schema.prisma`, enum `PromotionType` del backend) — determina qué
/// campo de descuento aplica: `percentage` usa `Promotion.discountPercentage`, `fixedAmount` usa
/// `Promotion.discountAmount`, `freeService` no descuenta un monto (el backend ya resuelve el
/// efecto final en `discountAmount`/`finalAmount` de `PromotionApplyResult`/`PromotionValidation`
/// — este campo es informativo, no hace falta ramificar la UI por tipo hoy).
enum PromotionType {
  percentage,
  fixedAmount,
  freeService;

  factory PromotionType.fromJson(String value) {
    return switch (value) {
      'PERCENTAGE' => PromotionType.percentage,
      'FIXED_AMOUNT' => PromotionType.fixedAmount,
      'FREE_SERVICE' => PromotionType.freeService,
      _ => throw ArgumentError('PromotionType desconocido: $value'),
    };
  }
}
