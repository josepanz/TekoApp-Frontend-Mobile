import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import 'categories_repository_provider.dart';

/// Catálogo de categorías activo+visible — online-only (ver `openspec/decisions.md`), sin
/// persistencia entre sesiones. `ref.invalidate(categoriesProvider)` para forzar un refetch.
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).fetchCategories();
});
