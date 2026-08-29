import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/providers/service_transition_controller_provider.dart';

class _MockDio extends Mock implements Dio {}

Map<String, dynamic> _serviceJson(String status) => {
      'id': 1,
      'referenceId': 'service-uuid-1',
      'userId': 1,
      'professionalId': 2,
      'categoryId': 3,
      'serviceTypeId': 4,
      'title': 'Reparación',
      'description': 'desc',
      'status': status,
      'latitude': -25.2,
      'longitude': -57.5,
      'address': 'Calle 1',
      'isUrgent': false,
      'createdAt': '2026-08-08T10:00:00.000Z',
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

  test('inicia el servicio y queda en estado exitoso', () async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/start'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/service-uuid-1/start'),
        data: _serviceJson('IN_PROGRESS'),
      ),
    );

    // Act
    await container
        .read(serviceTransitionControllerProvider.notifier)
        .start('service-uuid-1');

    // Assert
    final state = container.read(serviceTransitionControllerProvider);
    expect(state.hasError, isFalse);
  });

  test('completa el servicio y queda en estado exitoso', () async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/complete'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/services/service-uuid-1/complete',
        ),
        data: _serviceJson('COMPLETED'),
      ),
    );

    // Act
    await container
        .read(serviceTransitionControllerProvider.notifier)
        .complete('service-uuid-1');

    // Assert
    final state = container.read(serviceTransitionControllerProvider);
    expect(state.hasError, isFalse);
  });

  test(
    'deja un ServiceConflictFailure cuando el servicio ya cambió de estado',
    () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/start'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/start',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/services/service-uuid-1/start',
            ),
            statusCode: 409,
          ),
        ),
      );

      // Act
      await container
          .read(serviceTransitionControllerProvider.notifier)
          .start('service-uuid-1');

      // Assert
      final state = container.read(serviceTransitionControllerProvider);
      expect(state.hasError, isTrue);
    },
  );
}
