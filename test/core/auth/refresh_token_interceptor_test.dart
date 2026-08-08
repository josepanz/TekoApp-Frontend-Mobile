import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/refresh_token_interceptor.dart';
import 'package:tekoapp_mobile/core/auth/token_storage_keys.dart';

class _MockDio extends Mock implements Dio {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late _MockDio dio;
  late _MockSecureStorage secureStorage;
  late RefreshTokenInterceptor interceptor;
  late _MockErrorHandler handler;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(Options());
  });

  setUp(() {
    dio = _MockDio();
    secureStorage = _MockSecureStorage();
    interceptor = RefreshTokenInterceptor(dio, secureStorage: secureStorage);
    handler = _MockErrorHandler();
  });

  DioException unauthorizedError(String path) => DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 401,
        ),
      );

  test('deja pasar el error sin intentar refrescar si no es 401', () async {
    // Arrange
    final error = DioException(
      requestOptions: RequestOptions(path: '/auth/scope'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/scope'),
        statusCode: 500,
      ),
    );

    // Act
    interceptor.onError(error, handler);
    await pumpEventQueue();

    // Assert
    verify(() => handler.next(error)).called(1);
    verifyNever(
      () => dio.post<Map<String, dynamic>>(
        any(),
        options: any(named: 'options'),
      ),
    );
  });

  test(
    'deja pasar el error sin refrescar si el 401 viene del propio refresh-token',
    () async {
      // Arrange
      final error = unauthorizedError('/auth/refresh-token');

      // Act
      interceptor.onError(error, handler);
      await pumpEventQueue();

      // Assert
      verify(() => handler.next(error)).called(1);
      verifyNever(
        () => dio.post<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
        ),
      );
    },
  );

  test(
    'refresca el accessToken y reintenta el request original en un 401',
    () async {
      // Arrange
      final error = unauthorizedError('/auth/scope');
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/refresh-token',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/refresh-token'),
          data: {'accessToken': 'new-token'},
        ),
      );
      when(
        () => secureStorage.write(
          key: TokenStorageKeys.accessToken,
          value: 'new-token',
        ),
      ).thenAnswer((_) async {});
      final retryResponse = Response<dynamic>(
        requestOptions: RequestOptions(path: '/auth/scope'),
        data: {'ok': true},
      );
      when(() => dio.fetch<dynamic>(any()))
          .thenAnswer((_) async => retryResponse);

      // Act
      interceptor.onError(error, handler);
      await pumpEventQueue();

      // Assert
      verify(
        () => secureStorage.write(
          key: TokenStorageKeys.accessToken,
          value: 'new-token',
        ),
      ).called(1);
      verify(() => handler.resolve(retryResponse)).called(1);
    },
  );

  test(
    'limpia el accessToken y deja pasar el error original si el refresh también falla',
    () async {
      // Arrange
      final error = unauthorizedError('/auth/scope');
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/refresh-token',
          options: any(named: 'options'),
        ),
      ).thenThrow(unauthorizedError('/auth/refresh-token'));
      when(
        () => secureStorage.delete(key: TokenStorageKeys.accessToken),
      ).thenAnswer((_) async {});

      // Act
      interceptor.onError(error, handler);
      await pumpEventQueue();

      // Assert
      verify(
        () => secureStorage.delete(key: TokenStorageKeys.accessToken),
      ).called(1);
      verify(() => handler.next(error)).called(1);
    },
  );
}
