import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/payments/data/payments_repository.dart';
import 'package:tekoapp_mobile/features/payments/models/payment_failure.dart';
import 'package:tekoapp_mobile/features/payments/models/payment_method.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late PaymentsRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = PaymentsRepository(ApiClient(dio: dio));
  });

  Response<T> okResponse<T>(String path, T data) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  DioException errorResponse(
    String path, {
    required int statusCode,
    String? backendMessage,
  }) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
        data: backendMessage == null
            ? null
            : {
                'success': false,
                'error': {'code': statusCode, 'message': backendMessage},
              },
      ),
    );
  }

  Map<String, dynamic> paymentMethodJson({String id = 'pm-uuid-1'}) => {
        'id': id,
        'name': 'Visa terminada en 4242',
        'type': 'CREDIT_CARD',
        'provider': 'STRIPE',
        'isDefault': true,
        'isActive': true,
        'details': {'cardLast4': '4242'},
        'externalId': null,
      };

  Map<String, dynamic> paymentJson({String id = 'pay-uuid-1'}) => {
        'id': id,
        'userId': 1,
        'professionalId': 2,
        'serviceId': 'svc-uuid-1',
        'amount': 100000.0,
        'currencyCode': 'PYG',
        'fee': 3000.0,
        'tax': 10300.0,
        'totalAmount': 113300.0,
        'status': 'PENDING',
        'paymentMethod': 'CREDIT_CARD',
        'paymentProvider': 'STRIPE',
        'transactionId': 'txn-1',
        'createdAt': '2026-08-08T10:00:00.000Z',
      };

  group('fetchPaymentMethods', () {
    test('mapea la lista de métodos de pago propios', () async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
        (_) async => okResponse('/payments/methods', [paymentMethodJson()]),
      );

      // Act
      final result = await repository.fetchPaymentMethods();

      // Assert
      expect(result, hasLength(1));
      expect(result.single.id, 'pm-uuid-1');
      expect(result.single.type, PaymentMethodType.creditCard);
      expect(result.single.provider, PaymentProviderType.stripe);
    });

    test('devuelve una lista vacía cuando no hay métodos todavía', () async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>('/payments/methods'),
      ).thenAnswer((_) async => okResponse('/payments/methods', []));

      // Act
      final result = await repository.fetchPaymentMethods();

      // Assert
      expect(result, isEmpty);
    });

    test('clasifica un 5xx como servicio no disponible', () async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/payments/methods')).thenThrow(
        errorResponse('/payments/methods', statusCode: 503),
      );

      // Act & Assert
      await expectLater(
        repository.fetchPaymentMethods(),
        throwsA(isA<PaymentServiceUnavailableFailure>()),
      );
    });
  });

  group('createPaymentMethod', () {
    test('crea el método y lo retorna mapeado', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments/methods',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => okResponse('/payments/methods', paymentMethodJson()),
      );

      // Act
      final result = await repository.createPaymentMethod(
        name: 'Visa terminada en 4242',
        type: PaymentMethodType.creditCard,
        provider: PaymentProviderType.stripe,
        details: const {'cardLast4': '4242'},
      );

      // Assert
      expect(result.id, 'pm-uuid-1');
      final sentData = verify(
        () => dio.post<Map<String, dynamic>>(
          '/payments/methods',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(sentData['type'], 'CREDIT_CARD');
      expect(sentData['provider'], 'STRIPE');
    });

    test('propaga un 400 de validación sin mensaje de negocio puntual',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments/methods',
          data: any(named: 'data'),
        ),
      ).thenThrow(errorResponse('/payments/methods', statusCode: 400));

      // Act & Assert
      await expectLater(
        repository.createPaymentMethod(
          name: '',
          type: PaymentMethodType.cash,
          provider: PaymentProviderType.cash,
        ),
        throwsA(isA<PaymentValidationFailure>()),
      );
    });
  });

  group('setPaymentMethodAsDefault', () {
    test('marca el método como default', () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/payments/methods/pm-uuid-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async =>
            okResponse('/payments/methods/pm-uuid-1', paymentMethodJson()),
      );

      // Act
      final result = await repository.setPaymentMethodAsDefault('pm-uuid-1');

      // Assert
      expect(result.isDefault, isTrue);
    });
  });

  group('deletePaymentMethod', () {
    test('elimina el método sin error', () async {
      // Arrange
      when(
        () => dio.delete<void>('/payments/methods/pm-uuid-1'),
      ).thenAnswer(
        (_) async => okResponse<void>('/payments/methods/pm-uuid-1', null),
      );

      // Act & Assert
      await expectLater(
        repository.deletePaymentMethod('pm-uuid-1'),
        completes,
      );
    });

    test(
      'propaga el mensaje EXACTO del backend cuando es el único método activo',
      () async {
        // Arrange
        when(() => dio.delete<void>('/payments/methods/pm-uuid-1')).thenThrow(
          errorResponse(
            '/payments/methods/pm-uuid-1',
            statusCode: 400,
            backendMessage: 'No se puede eliminar el único método de pago',
          ),
        );

        // Act
        try {
          await repository.deletePaymentMethod('pm-uuid-1');
          fail('debía lanzar PaymentValidationFailure');
        } on PaymentValidationFailure catch (failure) {
          // Assert
          expect(
            failure.backendMessage,
            'No se puede eliminar el único método de pago',
          );
        }
      },
    );
  });

  group('createPayment', () {
    test('crea el pago mandando el professionalId como UUID', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => okResponse('/payments', paymentJson()));

      // Act
      final result = await repository.createPayment(
        professionalReferenceId: 'prof-uuid-1',
        serviceId: 'svc-uuid-1',
        amount: 100000,
        currencyCode: 'PYG',
        paymentMethod: PaymentMethodType.creditCard,
        paymentProvider: PaymentProviderType.stripe,
      );

      // Assert
      expect(result.id, 'pay-uuid-1');
      final sentData = verify(
        () => dio.post<Map<String, dynamic>>(
          '/payments',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(sentData['professionalId'], 'prof-uuid-1');
      expect(sentData['serviceId'], 'svc-uuid-1');
    });

    test('lanza PaymentValidationFailure con el mensaje si ya existe un pago',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        errorResponse(
          '/payments',
          statusCode: 400,
          backendMessage: 'Ya existe un pago para este servicio',
        ),
      );

      // Act
      try {
        await repository.createPayment(
          professionalReferenceId: 'prof-uuid-1',
          serviceId: 'svc-uuid-1',
          amount: 100000,
          currencyCode: 'PYG',
          paymentMethod: PaymentMethodType.creditCard,
          paymentProvider: PaymentProviderType.stripe,
        );
        fail('debía lanzar PaymentValidationFailure');
      } on PaymentValidationFailure catch (failure) {
        // Assert
        expect(failure.backendMessage, 'Ya existe un pago para este servicio');
      }
    });
  });

  group('fetchPayments', () {
    test('filtra por userId cuando se pasa (modo cliente)', () async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>(
          '/payments',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => okResponse('/payments', [paymentJson()]));

      // Act
      final result = await repository.fetchPayments(userId: 1);

      // Assert
      expect(result, hasLength(1));
      verify(
        () => dio.get<List<dynamic>>(
          '/payments',
          queryParameters: {'userId': 1},
        ),
      ).called(1);
    });

    test('filtra por professionalId cuando se pasa (modo profesional)',
        () async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>(
          '/payments',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async => okResponse('/payments', []));

      // Act
      await repository.fetchPayments(professionalId: 2);

      // Assert
      verify(
        () => dio.get<List<dynamic>>(
          '/payments',
          queryParameters: {'professionalId': 2},
        ),
      ).called(1);
    });
  });

  group('fetchPaymentById', () {
    test('retorna el detalle del pago', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
      ).thenAnswer(
        (_) async => okResponse('/payments/pay-uuid-1', paymentJson()),
      );

      // Act
      final result = await repository.fetchPaymentById('pay-uuid-1');

      // Assert
      expect(result.totalAmount, 113300.0);
    });
  });

  group('refundPayment', () {
    test('reembolsa y retorna el pago actualizado', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments/pay-uuid-1/refund',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => okResponse(
          '/payments/pay-uuid-1/refund',
          paymentJson()..['status'] = 'PARTIAL_REFUNDED',
        ),
      );

      // Act
      final result = await repository.refundPayment(
        'pay-uuid-1',
        amount: 50000,
        reason: 'customer_request',
      );

      // Assert
      expect(result.id, 'pay-uuid-1');
    });

    test('propaga el mensaje EXACTO cuando el monto excede lo disponible',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments/pay-uuid-1/refund',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        errorResponse(
          '/payments/pay-uuid-1/refund',
          statusCode: 400,
          backendMessage: 'El monto del reembolso excede el monto disponible',
        ),
      );

      // Act
      try {
        await repository.refundPayment(
          'pay-uuid-1',
          amount: 999999,
          reason: 'customer_request',
        );
        fail('debía lanzar PaymentValidationFailure');
      } on PaymentValidationFailure catch (failure) {
        // Assert
        expect(
          failure.backendMessage,
          'El monto del reembolso excede el monto disponible',
        );
      }
    });
  });

  group('clasificación de errores', () {
    test('un 409 se clasifica como PaymentConflictFailure', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments/pay-uuid-1/refund',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        errorResponse('/payments/pay-uuid-1/refund', statusCode: 409),
      );

      // Act & Assert
      await expectLater(
        repository.refundPayment(
          'pay-uuid-1',
          amount: 1000,
          reason: 'customer_request',
        ),
        throwsA(isA<PaymentConflictFailure>()),
      );
    });
  });
}
