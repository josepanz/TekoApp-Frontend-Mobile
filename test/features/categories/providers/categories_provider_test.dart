import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/categories/providers/categories_provider.dart';
import 'package:tekoapp_mobile/features/categories/providers/service_types_provider.dart';

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

  test('categoriesProvider expone el catálogo mapeado desde el backend',
      () async {
    // Arrange
    when(() => dio.get<List<dynamic>>('/categories')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/categories'),
        data: [
          {
            'id': 1,
            'referenceId': 'cat-uuid-1',
            'name': 'Plomería',
            'slug': 'plomeria',
            'icon': null,
            'color': null,
            'parentCategoryId': null,
          },
        ],
      ),
    );

    // Act
    final result = await container.read(categoriesProvider.future);

    // Assert
    expect(result, hasLength(1));
    expect(result.single.name, 'Plomería');
  });

  test(
    'serviceTypesProvider expone un estado vacío cuando el backend no tiene tipos activos',
    () async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/service-types')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/service-types'),
          data: [],
        ),
      );

      // Act
      final result = await container.read(serviceTypesProvider.future);

      // Assert
      expect(result, isEmpty);
    },
  );
}
