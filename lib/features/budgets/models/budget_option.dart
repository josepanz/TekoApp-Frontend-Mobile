import 'budget_line_item.dart';
import 'budget_line_item_type.dart';

/// `BudgetOptions` — recibida del backend, `totalPrice` siempre recalculado server-side. La UI
/// nunca confía en un total calculado solo client-side (ver
/// `openspec/specs/multi-option-quotes.md`, mismo criterio ya aplicado a promociones).
class BudgetOption {
  const BudgetOption({
    required this.referenceId,
    required this.label,
    required this.totalPrice,
    required this.isSelected,
    required this.lineItems,
    this.description,
    this.estimatedHours,
  });

  final String referenceId;
  final String label;
  final String? description;
  final double totalPrice;
  final double? estimatedHours;
  final bool isSelected;
  final List<BudgetLineItem> lineItems;

  factory BudgetOption.fromJson(Map<String, dynamic> json) {
    return BudgetOption(
      referenceId: json['referenceId'] as String,
      label: json['label'] as String,
      description: json['description'] as String?,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      isSelected: json['isSelected'] as bool,
      lineItems: (json['lineItems'] as List<dynamic>)
          .map((item) => BudgetLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Ítem de línea todavía sin enviar — estado local del armado en `BudgetBuilderScreen`, antes de
/// que el backend le asigne `referenceId`/recalcule `subtotal`.
class BudgetLineItemDraft {
  BudgetLineItemDraft({
    required this.itemType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.catalogItemReferenceId,
  });

  BudgetLineItemType itemType;
  String? catalogItemReferenceId;
  String description;
  double quantity;
  double unitPrice;

  double get subtotal => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'itemType': itemType.toJson(),
      if (catalogItemReferenceId != null)
        'catalogItemReferenceId': catalogItemReferenceId,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}

/// Opción todavía sin enviar — estado local del armado, antes del `PUT` que la persiste.
class BudgetOptionDraft {
  BudgetOptionDraft({
    required this.label,
    this.description,
    this.estimatedHours,
    List<BudgetLineItemDraft>? lineItems,
  }) : lineItems = lineItems ?? [];

  String label;
  String? description;
  double? estimatedHours;
  List<BudgetLineItemDraft> lineItems;

  double get totalPrice =>
      lineItems.fold(0, (sum, item) => sum + item.subtotal);

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (estimatedHours != null) 'estimatedHours': estimatedHours,
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
    };
  }
}
