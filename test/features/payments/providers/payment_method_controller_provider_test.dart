import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/payments/models/payment_method.dart';
import 'package:tekoapp_mobile/features/payments/providers/payment_method_controller_provider.dart';

class _MockDio extends Mock implements Dio {}

Map<String, dynamic> _paymentMethodJson() => {
      'id': 1,
      'referenceId': 'pm-uuid-1',
      'name': 'Visa terminada en 4242',
      'type': 'CREDIT_CARD',
      'provider': 'STRIPE',
      'isDefault': false,
      'isActive': true,
      'details': {'cardLast4': '4242'},
      'externalId': null,
    };

void main() {
  late _MockDio dio;
  late ProviderContainer container;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
    );
  });

  tearDown(() => container.dispose());

  test('create() da de alta el método y queda en estado exitoso', () async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>(
        '/payments/methods',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: _paymentMethodJson(),
      ),
    );

    // Act
    await container.read(paymentMethodControllerProvider.notifier).create(
          name: 'Visa terminada en 4242',
          type: PaymentMethodType.creditCard,
          provider: PaymentProviderType.stripe,
        );

    // Assert
    final state = container.read(paymentMethodControllerProvider);
    expect(state.hasError, isFalse);
  });

  test('delete() deja un error legible cuando es el único método activo',
      () async {
    // Arrange
    when(() => dio.delete<void>('/payments/methods/pm-uuid-1')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/payments/methods/pm-uuid-1'),
        response: Response(
          requestOptions: RequestOptions(
            path: '/payments/methods/pm-uuid-1',
          ),
          statusCode: 400,
          data: {
            'success': false,
            'error': {
              'code': 400,
              'message': 'No se puede eliminar el único método de pago',
            },
          },
        ),
      ),
    );

    // Act
    await container
        .read(paymentMethodControllerProvider.notifier)
        .delete('pm-uuid-1');

    // Assert
    final state = container.read(paymentMethodControllerProvider);
    expect(state.hasError, isTrue);
  });
}
