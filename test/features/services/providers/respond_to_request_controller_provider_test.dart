import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/providers/respond_to_request_controller_provider.dart';

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

  test('acepta la propuesta y queda en estado exitoso', () async {
    // Arrange
    when(
      () => dio.put<Map<String, dynamic>>(
        '/services/service-uuid-1/requests/request-uuid-1',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/services/service-uuid-1/requests/request-uuid-1',
        ),
        data: {
          'id': 'request-uuid-1',
          'serviceId': 'service-uuid-1',
          'professionalId': 2,
          'status': 'ACCEPTED',
          'createdAt': '2026-08-08T10:00:00.000Z',
        },
      ),
    );

    // Act
    await container
        .read(respondToRequestControllerProvider.notifier)
        .accept('service-uuid-1', 'request-uuid-1');

    // Assert
    final state = container.read(respondToRequestControllerProvider);
    expect(state.hasError, isFalse);
  });

  test(
    'deja un ServiceConflictFailure cuando el servicio ya no está PENDING',
    () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/services/service-uuid-1/requests/request-uuid-1',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/requests/request-uuid-1',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/services/service-uuid-1/requests/request-uuid-1',
            ),
            statusCode: 409,
          ),
        ),
      );

      // Act
      await container
          .read(respondToRequestControllerProvider.notifier)
          .accept('service-uuid-1', 'request-uuid-1');

      // Assert
      final state = container.read(respondToRequestControllerProvider);
      expect(state.hasError, isTrue);
    },
  );
}
