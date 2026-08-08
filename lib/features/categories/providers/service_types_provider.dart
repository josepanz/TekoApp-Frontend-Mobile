import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_type.dart';
import 'categories_repository_provider.dart';

/// Catálogo global de tipos de servicio — online-only, ver `categories_provider.dart`.
final serviceTypesProvider = FutureProvider<List<ServiceType>>((ref) {
  return ref.watch(categoriesRepositoryProvider).fetchServiceTypes();
});
