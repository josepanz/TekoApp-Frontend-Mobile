import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/contract.dart';
import '../models/contract_failure.dart';

/// `Contracts` — todo bajo JWT. Online-only, sin caché entre sesiones (mismo criterio que
/// `BudgetsRepository`).
class ContractsRepository {
  ContractsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Idempotente del lado backend: si ya existe un contrato para esa opción, lo devuelve en vez
  /// de fallar.
  Future<Contract> generateContract(String budgetOptionReferenceId) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/budget-options/$budgetOptionReferenceId/generate-contract',
      );
      return Contract.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<Contract> fetchContract(String contractReferenceId) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/contracts/$contractReferenceId',
      );
      return Contract.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// Hash de evidencia generado server-side — nunca lo manda el cliente.
  Future<Contract> signContract(
    String contractReferenceId,
    String fullName,
  ) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/contracts/$contractReferenceId/sign',
        data: {'fullName': fullName, 'accepted': true},
      );
      return Contract.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<String> fetchPdfUrl(String contractReferenceId) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/contracts/$contractReferenceId/pdf',
      );
      return response.data!['url'] as String;
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<List<MyContractSummary>> fetchMyContracts() async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/contracts',
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map(
            (json) => MyContractSummary.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  ContractFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final backendMessage = _extractBackendMessage(error);

    if (statusCode == 409) {
      return const ContractConflictFailure();
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return ContractValidationFailure(backendMessage);
    }
    return const ContractServiceUnavailableFailure();
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
