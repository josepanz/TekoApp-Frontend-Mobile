import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../../legal_consents/models/ai_disclosure_entity_type.dart';
import '../models/ai_disclosure.dart';
import '../models/ai_disclosure_failure.dart';

/// `/ai-disclosures/*` — todo el árbol exige JWT (ya cubierto por `BearerAuthInterceptor`). Ver
/// `TekoApp-Backend/openspec/specs/ai-content-disclosure.md` para el contrato completo.
class AiDisclosuresRepository {
  AiDisclosuresRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AiDisclosure> declare({
    required AiDisclosureEntityType entityType,
    required String entityReferenceId,
    String? note,
  }) async {
    try {
      final response = await _apiClient.raw.put<Map<String, dynamic>>(
        '/ai-disclosures',
        data: {
          'entityType': entityType.toJson(),
          'entityReferenceId': entityReferenceId,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return AiDisclosure.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<void> retract(
    AiDisclosureEntityType entityType,
    String entityReferenceId,
  ) async {
    try {
      await _apiClient.raw.delete<void>(
        '/ai-disclosures/${entityType.toJson()}/$entityReferenceId',
      );
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// `null` si el contenido no tiene disclosure — no es un error (ver spec del backend).
  Future<AiDisclosure?> fetch(
    AiDisclosureEntityType entityType,
    String entityReferenceId,
  ) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>?>(
        '/ai-disclosures/${entityType.toJson()}/$entityReferenceId',
      );
      final data = response.data;
      return data == null ? null : AiDisclosure.fromJson(data);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  AiDisclosureFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final backendMessage = _extractBackendMessage(error);

    if (statusCode == 404) {
      return AiDisclosureNotFoundFailure(backendMessage);
    }
    if (statusCode == 403) {
      return AiDisclosureForbiddenFailure(backendMessage);
    }
    if (statusCode == 400) {
      return AiDisclosureValidationFailure(backendMessage);
    }
    return const AiDisclosureServiceUnavailableFailure();
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
