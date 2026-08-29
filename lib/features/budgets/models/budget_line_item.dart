import 'budget_line_item_type.dart';

/// `BudgetLineItems` — recibido del backend, ya con `subtotal` recalculado server-side.
class BudgetLineItem {
  const BudgetLineItem({
    required this.referenceId,
    required this.itemType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.catalogItemReferenceId,
  });

  final String referenceId;
  final BudgetLineItemType itemType;
  final String? catalogItemReferenceId;
  final String description;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  factory BudgetLineItem.fromJson(Map<String, dynamic> json) {
    return BudgetLineItem(
      referenceId: json['referenceId'] as String,
      itemType: BudgetLineItemType.fromJson(json['itemType'] as String),
      catalogItemReferenceId: json['catalogItemReferenceId'] as String?,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}
