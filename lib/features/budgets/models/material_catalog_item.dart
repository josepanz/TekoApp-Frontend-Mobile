import 'material_quality_tier.dart';

/// `MaterialCatalog` — precio SUGERIDO, no un precio fijo/regulado (ver
/// `TekoApp-Frontend-Web/openspec/specs/material-catalog.md`, mismo criterio acá).
class MaterialCatalogItem {
  const MaterialCatalogItem({
    required this.referenceId,
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.qualityTier,
    required this.defaultPrice,
    required this.isActive,
    this.countryId,
  });

  final String referenceId;
  final int categoryId;
  final int? countryId;
  final String name;
  final String unit;
  final MaterialQualityTier qualityTier;
  final double defaultPrice;
  final bool isActive;

  factory MaterialCatalogItem.fromJson(Map<String, dynamic> json) {
    return MaterialCatalogItem(
      referenceId: json['referenceId'] as String,
      categoryId: json['categoryId'] as int,
      countryId: json['countryId'] as int?,
      name: json['name'] as String,
      unit: json['unit'] as String,
      qualityTier: MaterialQualityTier.fromJson(json['qualityTier'] as String),
      defaultPrice: (json['defaultPrice'] as num).toDouble(),
      isActive: json['isActive'] as bool,
    );
  }
}
