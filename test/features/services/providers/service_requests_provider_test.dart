import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/providers/service_requests_provider.dart';

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

  test('mapea las propuestas del servicio pedido', () async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/services/service-uuid-1/requests'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/services/service-uuid-1/requests',
        ),
        data: {
          'data': [
            {
              'id': 'request-uuid-1',
              'serviceId': 'service-uuid-1',
              'professionalId': 2,
              'status': 'PENDING',
              'createdAt': '2026-08-08T10:00:00.000Z',
            },
          ],
        },
      ),
    );

    // Act
    final result = await container.read(
      serviceRequestsProvider('service-uuid-1').future,
    );

    // Assert
    expect(result, hasLength(1));
    expect(result.single.professionalId, 2);
  });
}
