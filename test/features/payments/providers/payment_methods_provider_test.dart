import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/payments/providers/payment_methods_provider.dart';

class _MockDio extends Mock implements Dio {}

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

  test('expone los métodos de pago mapeados desde el backend', () async {
    // Arrange
    when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: [
          {
            'id': 1,
            'referenceId': 'pm-uuid-1',
            'name': 'Visa terminada en 4242',
            'type': 'CREDIT_CARD',
            'provider': 'STRIPE',
            'isDefault': true,
            'isActive': true,
            'details': {'cardLast4': '4242'},
            'externalId': null,
          },
        ],
      ),
    );

    // Act
    final result = await container.read(paymentMethodsProvider.future);

    // Assert
    expect(result, hasLength(1));
    expect(result.single.name, 'Visa terminada en 4242');
  });

  test('expone una lista vacía cuando todavía no hay métodos guardados',
      () async {
    // Arrange
    when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: [],
      ),
    );

    // Act
    final result = await container.read(paymentMethodsProvider.future);

    // Assert
    expect(result, isEmpty);
  });
}
