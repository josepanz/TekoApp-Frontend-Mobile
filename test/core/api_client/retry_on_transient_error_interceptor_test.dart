import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/retry_on_transient_error_interceptor.dart';

class _MockDio extends Mock implements Dio {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late _MockDio dio;
  late _MockErrorHandler handler;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
    registerFallbackValue(
      Response<dynamic>(requestOptions: RequestOptions(path: '/')),
    );
    registerFallbackValue(
      DioException(requestOptions: RequestOptions(path: '/')),
    );
  });

  setUp(() {
    dio = _MockDio();
    handler = _MockErrorHandler();
  });

  RetryOnTransientErrorInterceptor buildInterceptor() =>
      RetryOnTransientErrorInterceptor(
        dio,
        backoff: (_) => Duration.zero,
      );

  DioException transientError(String method) {
    final requestOptions = RequestOptions(path: '/services', method: method);
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.connectionError,
    );
  }

  DioException statusError(String method, int statusCode) {
    final requestOptions = RequestOptions(path: '/services', method: method);
    return DioException(
      requestOptions: requestOptions,
      response:
          Response(requestOptions: requestOptions, statusCode: statusCode),
    );
  }

  test(
    'GET que falla por timeout y luego responde: se reintenta y devuelve el dato',
    () async {
      // Arrange
      final error = transientError('GET');
      final successResponse = Response<dynamic>(
        requestOptions: error.requestOptions,
        data: {'ok': true},
      );
      when(
        () => dio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => successResponse);

      // Act
      buildInterceptor().onError(error, handler);
      await pumpEventQueue();

      // Assert
      verify(() => dio.fetch<dynamic>(any())).called(1);
      verify(() => handler.resolve(successResponse)).called(1);
      verifyNever(() => handler.next(any()));
    },
  );

  test('GET que falla 3 veces (original + 2 reintentos): propaga el error',
      () async {
    // Arrange
    final error = transientError('GET');
    when(() => dio.fetch<dynamic>(any())).thenThrow(transientError('GET'));

    // Act
    buildInterceptor().onError(error, handler);
    await pumpEventQueue();

    // Assert
    verify(() => dio.fetch<dynamic>(any())).called(2);
    verify(() => handler.next(any())).called(1);
  });

  test('un POST que falla por timeout no se reintenta', () async {
    // Arrange
    final error = transientError('POST');

    // Act
    buildInterceptor().onError(error, handler);
    await pumpEventQueue();

    // Assert
    verifyNever(() => dio.fetch<dynamic>(any()));
    verify(() => handler.next(error)).called(1);
  });

  test('un GET que falla con un 4xx real no se reintenta', () async {
    // Arrange
    final error = statusError('GET', 404);

    // Act
    buildInterceptor().onError(error, handler);
    await pumpEventQueue();

    // Assert
    verifyNever(() => dio.fetch<dynamic>(any()));
    verify(() => handler.next(error)).called(1);
  });

  test('un GET que falla con un 5xx real no se reintenta', () async {
    // Arrange — el backend sí respondió, no es un paquete perdido.
    final error = statusError('GET', 500);

    // Act
    buildInterceptor().onError(error, handler);
    await pumpEventQueue();

    // Assert
    verifyNever(() => dio.fetch<dynamic>(any()));
    verify(() => handler.next(error)).called(1);
  });
}
