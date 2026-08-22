import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/locations_failure.dart';
import '../models/nearby_professional.dart';
import '../models/professional_last_location.dart';

/// `/locations` — solo la parte REST (estado online + búsqueda de cercanos). El tiempo real vive
/// en `core/realtime/locations_socket_service.dart`.
class LocationsRepository {
  LocationsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      await _apiClient.raw.patch<void>(
        '/locations/online',
        data: {'isOnline': isOnline},
      );
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<List<NearbyProfessional>> fetchNearby({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.raw.get<List<dynamic>>(
        '/locations/nearby',
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );
      return (response.data ?? const [])
          .cast<Map<String, dynamic>>()
          .map(NearbyProfessional.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// Lanza `LocationsValidationFailure` (404) cuando el profesional todavía no tiene coordenadas
  /// registradas — un caso esperado (recién asignado, nunca activó el modo online), no un error a
  /// mostrarle al usuario.
  Future<ProfessionalLastLocation> fetchProfessionalLocation(
    int professionalId,
  ) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/locations/professional/$professionalId',
      );
      return ProfessionalLastLocation.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  LocationsFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return const LocationsValidationFailure();
    }
    return const LocationsServiceUnavailableFailure();
  }
}
