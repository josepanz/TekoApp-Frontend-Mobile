/// Espejo de `MaterialQualityTier` del backend (ver
/// `TekoApp-Backend/openspec/specs/multi-option-quotes.md`).
enum MaterialQualityTier {
  basic,
  standard,
  premium;

  factory MaterialQualityTier.fromJson(String value) {
    return switch (value) {
      'BASIC' => MaterialQualityTier.basic,
      'STANDARD' => MaterialQualityTier.standard,
      'PREMIUM' => MaterialQualityTier.premium,
      _ => throw ArgumentError('MaterialQualityTier desconocido: $value'),
    };
  }

  String toJson() {
    return switch (this) {
      MaterialQualityTier.basic => 'BASIC',
      MaterialQualityTier.standard => 'STANDARD',
      MaterialQualityTier.premium => 'PREMIUM',
    };
  }
}
