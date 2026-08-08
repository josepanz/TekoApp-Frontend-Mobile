import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/providers/request_service_controller_provider.dart';

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

  test('crea el servicio y queda en estado exitoso', () async {
    // Arrange
    when(
      () =>
          dio.post<Map<String, dynamic>>('/services', data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services'),
        data: {
          'id': 'service-uuid-1',
          'userId': 1,
          'professionalId': null,
          'categoryId': 3,
          'serviceTypeId': 4,
          'title': 'Reparación',
          'description': 'desc',
          'status': 'PENDING',
          'latitude': -25.2,
          'longitude': -57.5,
          'address': 'Calle 1',
          'isUrgent': false,
          'createdAt': '2026-08-08T10:00:00.000Z',
        },
      ),
    );

    // Act
    await container.read(requestServiceControllerProvider.notifier).submit(
          title: 'Reparación',
          description: 'desc',
          categoryId: 3,
          serviceTypeId: 4,
          latitude: -25.2,
          longitude: -57.5,
          address: 'Calle 1',
        );

    // Assert
    final state = container.read(requestServiceControllerProvider);
    expect(state.hasError, isFalse);
    expect(state.isLoading, isFalse);
  });

  test('deja un error de validación cuando el backend responde 400', () async {
    // Arrange
    when(
      () =>
          dio.post<Map<String, dynamic>>('/services', data: any(named: 'data')),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/services'),
        response: Response(
          requestOptions: RequestOptions(path: '/services'),
          statusCode: 400,
        ),
      ),
    );

    // Act
    await container.read(requestServiceControllerProvider.notifier).submit(
          title: 'Reparación',
          description: 'desc',
          categoryId: 3,
          serviceTypeId: 4,
          latitude: -25.2,
          longitude: -57.5,
          address: 'Calle 1',
        );

    // Assert
    final state = container.read(requestServiceControllerProvider);
    expect(state.hasError, isTrue);
  });
}
