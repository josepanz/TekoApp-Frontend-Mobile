/// Espejo de `BudgetLineItemType` del backend.
enum BudgetLineItemType {
  material,
  labor,
  other;

  factory BudgetLineItemType.fromJson(String value) {
    return switch (value) {
      'MATERIAL' => BudgetLineItemType.material,
      'LABOR' => BudgetLineItemType.labor,
      'OTHER' => BudgetLineItemType.other,
      _ => throw ArgumentError('BudgetLineItemType desconocido: $value'),
    };
  }

  String toJson() {
    return switch (this) {
      BudgetLineItemType.material => 'MATERIAL',
      BudgetLineItemType.labor => 'LABOR',
      BudgetLineItemType.other => 'OTHER',
    };
  }
}
