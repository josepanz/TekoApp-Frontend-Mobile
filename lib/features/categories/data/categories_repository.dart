import '../../../core/api_client/api_client.dart';
import '../models/category.dart';
import '../models/service_type.dart';

/// Catálogo público de categorías/tipos de servicio (`GET /categories`, `GET /service-types`) —
/// sin guard en el backend, pero el `ApiClient` ya adjunta el Bearer igual (no molesta).
///
/// Online-only (ver `openspec/decisions.md`): sin caché entre sesiones, cada consumidor decide
/// cuándo refrescar.
class CategoriesRepository {
  CategoriesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Category>> fetchCategories() async {
    final response = await _apiClient.raw.get<List<dynamic>>('/categories');
    return (response.data ?? [])
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ServiceType>> fetchServiceTypes() async {
    final response = await _apiClient.raw.get<List<dynamic>>('/service-types');
    return (response.data ?? [])
        .map((json) => ServiceType.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
