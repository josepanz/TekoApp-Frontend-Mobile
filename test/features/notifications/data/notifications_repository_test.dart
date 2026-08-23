import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/notifications/data/notifications_repository.dart';
import 'package:tekoapp_mobile/features/notifications/models/device_type.dart';
import 'package:tekoapp_mobile/features/notifications/models/notifications_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late NotificationsRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = NotificationsRepository(ApiClient(dio: dio));
  });

  group('registerFcmToken', () {
    test('manda el token y el tipo de dispositivo, devuelve el referenceId',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/notifications/fcm-tokens',
          data: {'token': 'a-fcm-token', 'deviceType': 'ANDROID'},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/notifications/fcm-tokens'),
          data: {
            'referenceId': 'token-ref-1',
            'deviceType': 'ANDROID',
            'createdAt': '2026-08-23T00:00:00.000Z',
          },
        ),
      );

      // Act
      final referenceId = await repository.registerFcmToken(
        token: 'a-fcm-token',
        deviceType: DeviceType.android,
      );

      // Assert
      expect(referenceId, 'token-ref-1');
    });

    test('traduce un error de red a NotificationsServiceUnavailableFailure',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/notifications/fcm-tokens',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/notifications/fcm-tokens'),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.registerFcmToken(
          token: 'a-fcm-token',
          deviceType: DeviceType.ios,
        ),
        throwsA(isA<NotificationsServiceUnavailableFailure>()),
      );
    });
  });

  group('removeFcmToken', () {
    test('da de baja el token por referenceId', () async {
      // Arrange
      when(
        () => dio.delete<void>('/notifications/fcm-tokens/token-ref-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/notifications/fcm-tokens/token-ref-1',
          ),
        ),
      );

      // Act & Assert — no debe lanzar
      await repository.removeFcmToken('token-ref-1');
      verify(
        () => dio.delete<void>('/notifications/fcm-tokens/token-ref-1'),
      ).called(1);
    });

    test('traduce un 404 a NotificationsValidationFailure', () async {
      // Arrange
      when(
        () => dio.delete<void>('/notifications/fcm-tokens/token-ref-1'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/notifications/fcm-tokens/token-ref-1',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/notifications/fcm-tokens/token-ref-1',
            ),
            statusCode: 404,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.removeFcmToken('token-ref-1'),
        throwsA(isA<NotificationsValidationFailure>()),
      );
    });
  });
}
