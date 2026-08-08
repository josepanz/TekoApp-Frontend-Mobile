import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/providers/service_detail_provider.dart';

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

  test('pide el detalle por id y lo mapea', () async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/service-uuid-1'),
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
    final result = await container.read(
      serviceDetailProvider('service-uuid-1').future,
    );

    // Assert
    expect(result.title, 'Reparación');
  });
}
