import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/account_deletion_failure.dart';
import '../models/deletion_blocker.dart';

/// `POST /auth/me/deletion-request` + `/cancel` (ver
/// `openspec/specs/account-deletion.md` y el contrato real en
/// `TekoApp-Backend/openspec/changes/platform-hardening-2026-09/I-01-account-deletion.md`).
/// Vive bajo `auth/me` en el backend, NO `users/me` — la spec de Mobile asumía el segundo, el
/// contrato real usa el primero (mismo dominio que `PUT /auth/me`, es autoservicio sobre la propia
/// cuenta). SIN `/v1`: el prefijo ya lo agrega el `baseUrl` de `ApiClient` (ver M-07).
///
/// Ninguno de los dos métodos devuelve el `UserSummary` actualizado — el caller (los controllers)
/// refresca la sesión completa vía `GET /auth/scope` para que `deletionScheduledAt` quede
/// consistente en todos lados, mismo patrón que `UpdateProfileController`.
class AccountDeletionRepository {
  AccountDeletionRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> requestDeletion() async {
    try {
      await _apiClient.raw.post<Map<String, dynamic>>(
        '/auth/me/deletion-request',
      );
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<void> cancelDeletion() async {
    try {
      await _apiClient.raw.post<Map<String, dynamic>>(
        '/auth/me/deletion-request/cancel',
      );
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  AccountDeletionFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final errorCode = _extractErrorCode(error);

    if (errorCode == 'DELETION_BLOCKED') {
      return AccountDeletionBlockedFailure(_extractBlockers(error));
    }
    if (errorCode == 'DELETION_ALREADY_REQUESTED') {
      return const AccountDeletionAlreadyRequestedFailure();
    }
    if (errorCode == 'DELETION_NOT_REQUESTED') {
      return const AccountDeletionNotRequestedFailure();
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return const AccountDeletionServiceUnavailableFailure();
    }
    if (error.response != null) {
      return const AccountDeletionServiceUnavailableFailure();
    }
    return const AccountDeletionNoConnectionFailure();
  }

  /// El envelope de error del backend es `{success:false, error:{code,message,errorCode?,
  /// details?}}` — `EnvelopeInterceptor` solo desenvuelve respuestas exitosas, así que esto llega
  /// crudo (mismo patrón que `LegalConsentsRepository`).
  String? _extractErrorCode(DioException error) {
    final errorField = _errorField(error);
    return errorField == null ? null : errorField['errorCode'] as String?;
  }

  /// `details: { blockers: [{type, count}, ...] }` — ver `HttpExceptionFilter`/
  /// `AccountDeletionService.requestDeletion` del backend. Una lista vacía si `details` no viene
  /// con la forma esperada (defensivo: nunca debería pasar si `errorCode` ya es
  /// `DELETION_BLOCKED`, pero un body inesperado no debe crashear la pantalla).
  List<DeletionBlocker> _extractBlockers(DioException error) {
    final errorField = _errorField(error);
    final details = errorField?['details'];
    if (details is! Map<String, dynamic>) return const [];
    final blockers = details['blockers'];
    if (blockers is! List) return const [];
    return blockers
        .whereType<Map<String, dynamic>>()
        .map(DeletionBlocker.fromJson)
        .toList();
  }

  Map<String, dynamic>? _errorField(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      return data['error'] as Map<String, dynamic>;
    }
    return null;
  }
}
