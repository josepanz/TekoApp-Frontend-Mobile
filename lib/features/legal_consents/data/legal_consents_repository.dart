import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/data_consents_history.dart';
import '../models/legal_consents_failure.dart';
import '../models/legal_document_version.dart';
import '../models/user_consent.dart';

/// `/legal/consents/*` + `/users/me/data-consents` + `/users/me/content/.../consent` — todo el
/// árbol exige JWT (ya cubierto por `BearerAuthInterceptor`). Ver
/// `TekoApp-Backend/openspec/specs/data-and-media-consent.md` para el contrato completo.
class LegalConsentsRepository {
  LegalConsentsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<LegalDocumentVersion>> fetchPendingConsents() async {
    try {
      final response = await _apiClient.raw.get<List<dynamic>>(
        '/legal/consents/pending',
      );
      return (response.data ?? [])
          .map(
            (json) =>
                LegalDocumentVersion.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<UserConsent> acceptConsent(String versionReferenceId) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/legal/consents/$versionReferenceId/accept',
      );
      return UserConsent.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<DataConsentsHistory> fetchDataConsentsHistory() async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/users/me/data-consents',
      );
      return DataConsentsHistory.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<void> revokeContentConsent(String contentReferenceId) async {
    try {
      await _apiClient.raw.delete<void>(
        '/users/me/content/$contentReferenceId/consent',
      );
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  LegalConsentsFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final errorCode = _extractErrorCode(error);
    final backendMessage = _extractBackendMessage(error);

    if (statusCode == 404) {
      return LegalConsentsNotFoundFailure(backendMessage);
    }
    if (errorCode == 'LEGAL_HOLD_ACTIVE') {
      return LegalConsentsLegalHoldFailure(backendMessage);
    }
    if (statusCode == 409) {
      return LegalConsentsConflictFailure(backendMessage);
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return LegalConsentsValidationFailure(backendMessage);
    }
    return const LegalConsentsServiceUnavailableFailure();
  }

  /// El envelope de error del backend es `{success:false, error:{code,message,errorCode?,...}}` —
  /// `EnvelopeInterceptor` solo desenvuelve respuestas exitosas, así que esto llega crudo.
  String? _extractBackendMessage(DioException error) {
    final errorField = _errorField(error);
    return errorField == null ? null : errorField['message'] as String?;
  }

  /// `errorCode` — identificador estable para distinguir errores puntuales (`LEGAL_HOLD_ACTIVE`)
  /// de cualquier otro 409/403 genérico. Ver `TekoApp-Backend/openspec/decisions.md`, amendment
  /// 2026-08-25.
  String? _extractErrorCode(DioException error) {
    final errorField = _errorField(error);
    return errorField == null ? null : errorField['errorCode'] as String?;
  }

  Map<String, dynamic>? _errorField(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      return data['error'] as Map<String, dynamic>;
    }
    return null;
  }
}
