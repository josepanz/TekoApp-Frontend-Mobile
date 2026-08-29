import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/material_catalog_item.dart';
import 'budgets_repository_provider.dart';

/// Catálogo de materiales de una categoría — `autoDispose` (ver `openspec/decisions.md`), solo
/// tiene sentido mientras se está armando un presupuesto para esa categoría.
final materialCatalogProvider = FutureProvider.autoDispose
    .family<List<MaterialCatalogItem>, int>((ref, categoryId) {
  return ref
      .watch(budgetsRepositoryProvider)
      .fetchMaterialCatalog(categoryId: categoryId);
});
