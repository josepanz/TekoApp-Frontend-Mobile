import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api_client/api_client.dart';
import '../models/service_progress_entry.dart';
import '../models/service_progress_failure.dart';

/// `/services/:id/progress` — todo el árbol exige JWT (ya cubierto por `BearerAuthInterceptor`).
/// Ver `TekoApp-Backend/openspec/specs/work-progress-log.md` para el contrato completo.
///
/// **Las fotos NO viajan en el POST de creación** — se suben antes, una por una, vía
/// `POST /uploads/image` (mismo endpoint genérico que ya usa `ProfileRepository.uploadAvatar`), y
/// solo las keys de S3 resultantes se mandan en el body JSON de `createEntry`. La spec original de
/// esta fase asumía multipart directo; se corrigió tras verificar el patrón real del backend (ver
/// `openspec/decisions.md`).
class ServiceProgressRepository {
  ServiceProgressRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/uploads/image',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        }),
      );
      return response.data!['key'] as String;
    } on DioException {
      throw const ServiceProgressServiceUnavailableFailure();
    }
  }

  Future<ServiceProgressEntry> createEntry({
    required String serviceId,
    String? note,
    List<String> images = const [],
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/services/$serviceId/progress',
        data: {
          if (note != null && note.isNotEmpty) 'note': note,
          if (images.isNotEmpty) 'images': images,
        },
      );
      return ServiceProgressEntry.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// `images` guarda keys de S3, no URLs — resuelve una URL presignada fresca para mostrarla,
  /// nunca persistir el resultado más allá de la pantalla actual (mismo criterio que
  /// `avatarKey`/`avatarUrl`, ver `.claude/rules/auth.md`).
  Future<String> resolvePhotoUrl(String key) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/uploads/presigned-url',
        queryParameters: {'key': key},
      );
      return response.data!['url'] as String;
    } on DioException {
      throw const ServiceProgressServiceUnavailableFailure();
    }
  }

  Future<List<ServiceProgressEntry>> listByService(String serviceId) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/services/$serviceId/progress',
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((e) => ServiceProgressEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<void> deleteEntry({
    required String serviceId,
    required String entryId,
  }) async {
    try {
      await _apiClient.raw.delete<void>(
        '/services/$serviceId/progress/$entryId',
      );
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  ServiceProgressFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final backendMessage = _extractBackendMessage(error);

    if (statusCode == 404) {
      return const ServiceProgressNotFoundFailure();
    }
    if (statusCode == 403) {
      return ServiceProgressForbiddenFailure(backendMessage);
    }
    if (statusCode == 409) {
      return ServiceProgressConflictFailure(backendMessage);
    }
    if (statusCode == 400) {
      return ServiceProgressValidationFailure(backendMessage);
    }
    return const ServiceProgressServiceUnavailableFailure();
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
