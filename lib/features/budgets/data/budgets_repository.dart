import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/budget_failure.dart';
import '../models/budget_option.dart';
import '../models/material_catalog_item.dart';

/// `MaterialCatalog`/`BudgetOptions`/`BudgetLineItems` — todo bajo JWT (ver
/// `BearerAuthInterceptor`). Online-only, sin caché entre sesiones (mismo criterio que
/// `ServicesRepository`).
class BudgetsRepository {
  BudgetsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Catálogo activo de una categoría — se pide con `pageSize` grande porque el armado de
  /// presupuesto necesita la lista completa para elegir, no una página a la vez (a diferencia del
  /// panel admin de Web, que sí pagina de verdad).
  Future<List<MaterialCatalogItem>> fetchMaterialCatalog({
    required int categoryId,
  }) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/material-catalog',
        queryParameters: {
          'categoryId': categoryId,
          'isActive': true,
          'page': 1,
          'pageSize': 100,
        },
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map(
            (json) =>
                MaterialCatalogItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<List<BudgetOption>> fetchBudgetOptions(
    String serviceId,
    String requestId,
  ) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/services/$serviceId/requests/$requestId/budget-options',
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => BudgetOption.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// Reemplaza el set completo de opciones — el backend recalcula `totalPrice`/`subtotal` siempre,
  /// nunca confía en lo que manda acá (ver `openspec/specs/multi-option-quotes.md`).
  Future<List<BudgetOption>> replaceBudgetOptions(
    String serviceId,
    String requestId,
    List<BudgetOptionDraft> options,
  ) async {
    try {
      final response = await _apiClient.raw.put<Map<String, dynamic>>(
        '/services/$serviceId/requests/$requestId/budget-options',
        data: {'options': options.map((option) => option.toJson()).toList()},
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => BudgetOption.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// Elige una opción — dispara la misma aceptación transaccional que
  /// `ServicesRepository.respondToRequest` (competidoras auto-rechazadas server-side).
  Future<BudgetOption> selectBudgetOption(
    String serviceId,
    String requestId,
    String optionReferenceId,
  ) async {
    try {
      final response = await _apiClient.raw.patch<Map<String, dynamic>>(
        '/services/$serviceId/requests/$requestId/budget-options/$optionReferenceId/select',
      );
      return BudgetOption.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  BudgetFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final backendMessage = _extractBackendMessage(error);

    if (statusCode == 409) {
      return const BudgetConflictFailure();
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return BudgetValidationFailure(backendMessage);
    }
    return const BudgetServiceUnavailableFailure();
  }

  /// El envelope de error del backend es `{success:false, error:{code,message,...}}` —
  /// `EnvelopeInterceptor` solo desenvuelve respuestas exitosas, así que esto llega crudo.
  String? _extractBackendMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['message'] as String?;
    }
    return null;
  }
}
