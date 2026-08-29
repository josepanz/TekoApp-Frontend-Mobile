import 'tip_mode.dart';

/// `TipResponseDTO` — propina de un pago, siempre 100% para el profesional (nunca entra en el
/// cálculo de comisión de la plataforma) y nunca fusionada a `Payment.totalAmount`.
class Tip {
  const Tip({
    required this.referenceId,
    required this.mode,
    required this.amount,
    required this.currencyCode,
    required this.createdAt,
    this.percentage,
  });

  final String referenceId;
  final TipMode mode;

  /// Solo poblado cuando `mode == TipMode.percentage`.
  final double? percentage;
  final double amount;
  final String currencyCode;
  final DateTime createdAt;

  factory Tip.fromJson(Map<String, dynamic> json) {
    return Tip(
      referenceId: json['referenceId'] as String,
      mode: TipMode.fromJson(json['mode'] as String),
      percentage: (json['percentage'] as num?)?.toDouble(),
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// `TipConfigResponseDTO` — Paraguay-only por ahora, siempre resuelve el default global.
class TipConfig {
  const TipConfig({
    required this.isEnabled,
    required this.isMandatory,
    required this.suggestedPercentages,
    required this.allowFreeAmount,
  });

  final bool isEnabled;

  /// Informativo — la UI debería mostrar el paso de propina como no salteable cuando es true. El
  /// backend no bloquea el pago si el cliente no deja propina (ver decisions.md).
  final bool isMandatory;
  final List<int> suggestedPercentages;
  final bool allowFreeAmount;

  factory TipConfig.fromJson(Map<String, dynamic> json) {
    return TipConfig(
      isEnabled: json['isEnabled'] as bool,
      isMandatory: json['isMandatory'] as bool,
      suggestedPercentages: (json['suggestedPercentages'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      allowFreeAmount: json['allowFreeAmount'] as bool,
    );
  }
}
