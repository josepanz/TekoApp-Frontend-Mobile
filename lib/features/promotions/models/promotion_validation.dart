import 'promotion.dart';

/// Resultado de `POST /promotions/validate` — preview SIN efecto secundario (no incrementa el uso
/// de la promoción). Un código inválido/vencido/agotado NO es un error HTTP: el backend responde
/// 200 con `isValid: false` y un `message` explicando por qué (ver `openspec/decisions.md`).
class PromotionValidation {
  const PromotionValidation({
    required this.isValid,
    required this.discountAmount,
    this.promotion,
    this.message,
  });

  final bool isValid;
  final double discountAmount;
  final Promotion? promotion;
  final String? message;

  factory PromotionValidation.fromJson(Map<String, dynamic> json) {
    return PromotionValidation(
      isValid: json['isValid'] as bool,
      discountAmount: (json['discountAmount'] as num).toDouble(),
      promotion: json['promotion'] != null
          ? Promotion.fromJson(json['promotion'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}
