import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/consent_required_interceptor.dart';

class _MockDio extends Mock implements Dio {}

class _MockErrorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late _MockDio dio;
  late _MockErrorHandler handler;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    dio = _MockDio();
    handler = _MockErrorHandler();
  });

  DioException errorWith({
    required String path,
    required int statusCode,
    String? errorCode,
  }) {
    final requestOptions = RequestOptions(path: path);
    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: statusCode,
        data: {
          'success': false,
          'error': {
            'code': statusCode,
            'message': 'x',
            if (errorCode != null) 'errorCode': errorCode,
          },
        },
      ),
    );
  }

  test('deja pasar el error sin pedir consentimiento si no es 403', () async {
    // Arrange
    final error = errorWith(path: '/services', statusCode: 500);
    var wasCalled = false;
    final interceptor = ConsentRequiredInterceptor(dio, () async {
      wasCalled = true;
      return true;
    });

    // Act
    interceptor.onError(error, handler);
    await pumpEventQueue();

    // Assert
    expect(wasCalled, isFalse);
    verify(() => handler.next(error)).called(1);
  });

  test(
    'deja pasar el error sin pedir consentimiento si el 403 no tiene errorCode CONSENT_REQUIRED',
    () async {
      // Arrange — un 403 genérico de permisos, no de consentimiento.
      final error = errorWith(path: '/admin/x', statusCode: 403);
      var wasCalled = false;
      final interceptor = ConsentRequiredInterceptor(dio, () async {
        wasCalled = true;
        return true;
      });

      // Act
      interceptor.onError(error, handler);
      await pumpEventQueue();

      // Assert
      expect(wasCalled, isFalse);
      verify(() => handler.next(error)).called(1);
    },
  );

  test(
    'no reintenta un 403 CONSENT_REQUIRED que venga de /legal/consents (evita loop)',
    () async {
      // Arrange
      final error = errorWith(
        path: '/legal/consents/ref-1/accept',
        statusCode: 403,
        errorCode: 'CONSENT_REQUIRED',
      );
      var wasCalled = false;
      final interceptor = ConsentRequiredInterceptor(dio, () async {
        wasCalled = true;
        return true;
      });

      // Act
      interceptor.onError(error, handler);
      await pumpEventQueue();

      // Assert
      expect(wasCalled, isFalse);
      verify(() => handler.next(error)).called(1);
    },
  );

  test(
    'pide consentimiento y reintenta el request original si el usuario acepta',
    () async {
      // Arrange
      final error = errorWith(
        path: '/professional-documents',
        statusCode: 403,
        errorCode: 'CONSENT_REQUIRED',
      );
      final interceptor = ConsentRequiredInterceptor(
        dio,
        () async => true,
      );
      final retryResponse = Response<dynamic>(
        requestOptions: error.requestOptions,
        data: {'ok': true},
      );
      when(
        () => dio.fetch<dynamic>(any()),
      ).thenAnswer((_) async => retryResponse);

      // Act
      interceptor.onError(error, handler);
      await pumpEventQueue();

      // Assert
      verify(() => handler.resolve(retryResponse)).called(1);
      verifyNever(() => handler.next(error));
    },
  );

  test(
    'deja pasar el error original si el usuario NO acepta el consentimiento',
    () async {
      // Arrange
      final error = errorWith(
        path: '/professional-documents',
        statusCode: 403,
        errorCode: 'CONSENT_REQUIRED',
      );
      final interceptor = ConsentRequiredInterceptor(
        dio,
        () async => false,
      );

      // Act
      interceptor.onError(error, handler);
      await pumpEventQueue();

      // Assert
      verify(() => handler.next(error)).called(1);
      verifyNever(() => dio.fetch<dynamic>(any()));
    },
  );

  test(
    'deja pasar el error del reintento si vuelve a fallar tras aceptar',
    () async {
      // Arrange
      final error = errorWith(
        path: '/professional-documents',
        statusCode: 403,
        errorCode: 'CONSENT_REQUIRED',
      );
      final interceptor = ConsentRequiredInterceptor(
        dio,
        () async => true,
      );
      final retryError =
          errorWith(path: '/professional-documents', statusCode: 500);
      when(() => dio.fetch<dynamic>(any())).thenThrow(retryError);

      // Act
      interceptor.onError(error, handler);
      await pumpEventQueue();

      // Assert
      verify(() => handler.next(retryError)).called(1);
    },
  );
}
