import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/categories/data/categories_repository.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late CategoriesRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = CategoriesRepository(ApiClient(dio: dio));
  });

  Response<List<dynamic>> listResponse(String path, List<dynamic> data) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  group('fetchCategories', () {
    test('mapea el listado de categorías activas', () async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/categories')).thenAnswer(
        (_) async => listResponse('/categories', [
          {
            'id': 1,
            'referenceId': 'cat-uuid-1',
            'name': 'Plomería',
            'slug': 'plomeria',
            'icon': 'wrench-outline',
            'color': '#2ecc71',
            'parentCategoryId': null,
          },
        ]),
      );

      // Act
      final result = await repository.fetchCategories();

      // Assert
      expect(result, hasLength(1));
      expect(result.single.id, 1);
      expect(result.single.referenceId, 'cat-uuid-1');
      expect(result.single.name, 'Plomería');
    });

    test('devuelve una lista vacía cuando no hay categorías todavía', () async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>('/categories'),
      ).thenAnswer((_) async => listResponse('/categories', []));

      // Act
      final result = await repository.fetchCategories();

      // Assert
      expect(result, isEmpty);
    });
  });

  group('fetchServiceTypes', () {
    test('mapea el listado global de tipos de servicio', () async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/service-types')).thenAnswer(
        (_) async => listResponse('/service-types', [
          {'id': 1, 'name': 'Instalación'},
          {'id': 2, 'name': 'Reparación'},
        ]),
      );

      // Act
      final result = await repository.fetchServiceTypes();

      // Assert
      expect(result, hasLength(2));
      expect(result.map((type) => type.name), ['Instalación', 'Reparación']);
    });
  });
}
