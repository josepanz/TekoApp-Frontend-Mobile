import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/device_type.dart';
import '../models/notifications_failure.dart';

/// `/notifications/fcm-tokens` — registro/baja del token FCM del dispositivo actual. Ver
/// `TekoApp-Backend/src/api/notifications/controllers/notifications.controller.ts`.
class NotificationsRepository {
  NotificationsRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Devuelve el `referenceId` del token ya registrado — hace falta persistirlo para poder
  /// darlo de baja después (`removeFcmToken`), el backend no lo resuelve por el token crudo.
  Future<String> registerFcmToken({
    required String token,
    required DeviceType deviceType,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/notifications/fcm-tokens',
        data: {'token': token, 'deviceType': deviceType.toJson()},
      );
      return response.data!['referenceId'] as String;
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<void> removeFcmToken(String referenceId) async {
    try {
      await _apiClient.raw
          .delete<void>('/notifications/fcm-tokens/$referenceId');
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  NotificationsFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return const NotificationsValidationFailure();
    }
    return const NotificationsServiceUnavailableFailure();
  }
}
