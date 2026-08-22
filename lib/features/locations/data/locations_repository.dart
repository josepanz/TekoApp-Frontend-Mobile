import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/locations_failure.dart';

/// `/locations` — solo la parte REST (estado online). El tiempo real vive en
/// `core/realtime/locations_socket_service.dart`.
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

  LocationsFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return const LocationsValidationFailure();
    }
    return const LocationsServiceUnavailableFailure();
  }
}
