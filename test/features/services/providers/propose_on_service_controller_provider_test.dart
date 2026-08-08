import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/providers/propose_on_service_controller_provider.dart';

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

  test('se propone sobre el servicio y queda en estado exitoso', () async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>(
        '/services/service-uuid-1/requests',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/services/service-uuid-1/requests',
        ),
        data: {
          'id': 'request-uuid-1',
          'serviceId': 'service-uuid-1',
          'professionalId': 2,
          'status': 'PENDING',
          'createdAt': '2026-08-08T10:00:00.000Z',
        },
      ),
    );

    // Act
    await container
        .read(proposeOnServiceControllerProvider.notifier)
        .submit('service-uuid-1');

    // Assert
    final state = container.read(proposeOnServiceControllerProvider);
    expect(state.hasError, isFalse);
  });

  test(
    'deja un ServiceConflictFailure cuando el servicio ya no está disponible',
    () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services/service-uuid-1/requests',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/requests',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/services/service-uuid-1/requests',
            ),
            statusCode: 409,
          ),
        ),
      );

      // Act
      await container
          .read(proposeOnServiceControllerProvider.notifier)
          .submit('service-uuid-1');

      // Assert
      final state = container.read(proposeOnServiceControllerProvider);
      expect(state.hasError, isTrue);
    },
  );
}
