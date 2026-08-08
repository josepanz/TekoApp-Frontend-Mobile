import 'promotion.dart';

/// Resultado de `POST /promotions/apply` — a diferencia de `validate`, esto SÍ tiene efecto
/// secundario (incrementa el uso de la promoción) — solo se llama al confirmar el pago, nunca
/// como preview (ver `openspec/decisions.md`). `finalAmount` es el monto con el descuento ya
/// aplicado, listo para mandar como `amount` en `POST /payments`.
class PromotionApplyResult {
  const PromotionApplyResult({
    required this.success,
    required this.discountAmount,
    required this.finalAmount,
    this.promotion,
    this.message,
  });

  final bool success;
  final double discountAmount;
  final double finalAmount;
  final Promotion? promotion;
  final String? message;

  factory PromotionApplyResult.fromJson(Map<String, dynamic> json) {
    return PromotionApplyResult(
      success: json['success'] as bool,
      discountAmount: (json['discountAmount'] as num).toDouble(),
      finalAmount: (json['finalAmount'] as num).toDouble(),
      promotion: json['promotion'] != null
          ? Promotion.fromJson(json['promotion'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}
