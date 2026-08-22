import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/locations/data/locations_repository.dart';
import 'package:tekoapp_mobile/features/locations/models/locations_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late LocationsRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = LocationsRepository(ApiClient(dio: dio));
  });

  group('setOnlineStatus', () {
    test('manda isOnline al backend', () async {
      // Arrange
      when(
        () => dio.patch<void>('/locations/online', data: {'isOnline': true}),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/locations/online'),
        ),
      );

      // Act & Assert — no debe lanzar
      await repository.setOnlineStatus(true);
      verify(
        () => dio.patch<void>('/locations/online', data: {'isOnline': true}),
      ).called(1);
    });

    test('traduce un 4xx a LocationsValidationFailure', () async {
      // Arrange
      when(
        () =>
            dio.patch<void>('/locations/online', data: {'isOnline': false}),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/locations/online'),
          response: Response(
            requestOptions: RequestOptions(path: '/locations/online'),
            statusCode: 404,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.setOnlineStatus(false),
        throwsA(isA<LocationsValidationFailure>()),
      );
    });

    test('traduce un error de red a LocationsServiceUnavailableFailure', () async {
      // Arrange
      when(
        () => dio.patch<void>('/locations/online', data: {'isOnline': true}),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/locations/online')),
      );

      // Act & Assert
      await expectLater(
        repository.setOnlineStatus(true),
        throwsA(isA<LocationsServiceUnavailableFailure>()),
      );
    });
  });
}
