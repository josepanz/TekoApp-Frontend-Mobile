import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';

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

  test(
    'devuelve los nombres de los países cuando el backend responde con datos',
    () async {
      // Arrange
      when(() => dio.get<Map<String, dynamic>>('/countries')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/countries'),
          data: {
            'data': [
              {'commonName': 'Paraguay'},
              {'commonName': 'Argentina'},
            ],
            'pagination': {
              'total': 2,
              'page': 1,
              'pageSize': 10,
              'totalPages': 1,
            },
          },
        ),
      );

      // Act
      final result = await container.read(networkSmokeCheckProvider.future);

      // Assert
      expect(result, ['Paraguay', 'Argentina']);
    },
  );

  test(
    'devuelve una lista vacía cuando el backend responde sin países',
    () async {
      // Arrange
      when(() => dio.get<Map<String, dynamic>>('/countries')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/countries'),
          data: {
            'data': <Map<String, dynamic>>[],
            'pagination': {
              'total': 0,
              'page': 1,
              'pageSize': 10,
              'totalPages': 0,
            },
          },
        ),
      );

      // Act
      final result = await container.read(networkSmokeCheckProvider.future);

      // Assert
      expect(result, isEmpty);
    },
  );

  test(
    'propaga el error cuando el backend no responde',
    () async {
      // Arrange
      when(() => dio.get<Map<String, dynamic>>('/countries')).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/countries')),
      );

      // Act & Assert
      await expectLater(
        container.read(networkSmokeCheckProvider.future),
        throwsA(isA<DioException>()),
      );
    },
  );
}
