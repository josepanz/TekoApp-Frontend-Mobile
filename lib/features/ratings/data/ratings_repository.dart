import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/professional_rating_stats.dart';
import '../models/rating.dart';
import '../models/rating_failure.dart';
import '../models/rating_type.dart';
import '../models/user_rating_stats.dart';

/// `/ratings` — todo el árbol exige JWT (ya cubierto por `BearerAuthInterceptor`).
///
/// OJO: pese a que el backend nombra el campo/parámetro `serviceRequestId` en
/// `CreateRatingRequestDTO`, `CreateProfessionalToClientRatingRequestDTO` y en
/// `GET /ratings/service/:serviceRequestId`, en los tres casos el valor se resuelve internamente
/// vía `findServiceByReferenceId` (`ratings.service.ts#resolveServiceId`) — es decir, es el
/// `referenceId` (UUID) del `Service` mismo, NO el de un `ServiceRequest` (propuesta). Se manda
/// `service.referenceId` directamente, sin buscar ninguna propuesta `ACCEPTED` (confirmado
/// leyendo el código real del backend, ver `openspec/decisions.md`).
class RatingsRepository {
  RatingsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Rating> rateProfessional({
    required String professionalReferenceId,
    required String serviceReferenceId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/ratings',
        data: {
          'professionalId': professionalReferenceId,
          'serviceRequestId': serviceReferenceId,
          'type': RatingType.clientToProfessional.toJson(),
          'rating': rating,
          if (comment != null) 'comment': comment,
        },
      );
      return Rating.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<Rating> rateClient({
    required String clientReferenceId,
    required String serviceReferenceId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/ratings/professional-to-client',
        data: {
          'clientId': clientReferenceId,
          'serviceRequestId': serviceReferenceId,
          'rating': rating,
          if (comment != null) 'comment': comment,
        },
      );
      return Rating.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<List<Rating>> fetchForService(String serviceReferenceId) async {
    try {
      final response = await _apiClient.raw.get<List<dynamic>>(
        '/ratings/service/$serviceReferenceId',
      );
      return (response.data ?? [])
          .map((json) => Rating.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// Estadísticas propias como cliente (dadas/recibidas) — `/ratings/me/stats` resuelve el
  /// userId desde el token, evita que el cliente necesite conocer su propio id interno (que
  /// `GET /auth/scope` nunca expone, ver `openspec/decisions.md`).
  Future<UserRatingStats> fetchMyStats() async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/ratings/me/stats',
      );
      return UserRatingStats.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// Estadísticas del profesional (recibidas como profesional) — a diferencia de `fetchMyStats`,
  /// este endpoint SÍ pide el id interno (Int) del profesional, ya que `Professionals` expone
  /// `id`+`referenceId` por separado desde antes de la Fase 0008 (ver `ProfessionalProfile`).
  Future<ProfessionalRatingStats> fetchProfessionalStats(
    int professionalId,
  ) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/ratings/professional/$professionalId/average',
      );
      return ProfessionalRatingStats.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  RatingFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final backendMessage = _extractBackendMessage(error);
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return RatingValidationFailure(backendMessage);
    }
    return const RatingServiceUnavailableFailure();
  }

  String? _extractBackendMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorField = data['error'];
      if (errorField is Map<String, dynamic>) {
        return errorField['message'] as String?;
      }
    }
    return null;
  }
}
