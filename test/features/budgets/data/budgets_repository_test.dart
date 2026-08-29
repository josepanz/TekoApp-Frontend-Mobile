import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/budgets/data/budgets_repository.dart';
import 'package:tekoapp_mobile/features/budgets/models/budget_failure.dart';
import 'package:tekoapp_mobile/features/budgets/models/budget_line_item_type.dart';
import 'package:tekoapp_mobile/features/budgets/models/budget_option.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late BudgetsRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = BudgetsRepository(ApiClient(dio: dio));
  });

  Map<String, dynamic> materialCatalogItemJson() {
    return {
      'referenceId': 'catalog-1',
      'categoryId': 3,
      'countryId': null,
      'name': 'Cerámica esmaltada 30x30',
      'unit': 'm2',
      'qualityTier': 'STANDARD',
      'defaultPrice': 45000,
      'isActive': true,
    };
  }

  Map<String, dynamic> budgetOptionJson({bool isSelected = false}) {
    return {
      'referenceId': 'option-1',
      'label': 'Estándar',
      'description': null,
      'totalPrice': 450000,
      'estimatedHours': 8,
      'isSelected': isSelected,
      'lineItems': [
        {
          'referenceId': 'line-1',
          'itemType': 'MATERIAL',
          'catalogItemReferenceId': 'catalog-1',
          'description': 'Cerámica esmaltada 30x30',
          'quantity': 10,
          'unitPrice': 45000,
          'subtotal': 450000,
        },
      ],
    };
  }

  DioException conflictError(String path) => DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 409,
        ),
      );

  DioException validationError(String path, {String? message}) => DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 400,
          data: message == null
              ? null
              : {
                  'error': {'message': message},
                },
        ),
      );

  group('fetchMaterialCatalog', () {
    test('mapea el catálogo de la categoría pedida', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>(
          '/material-catalog',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/material-catalog'),
          data: {
            'data': [materialCatalogItemJson()],
            'pagination': {
              'total': 1,
              'page': 1,
              'pageSize': 100,
              'totalPages': 1,
            },
          },
        ),
      );

      // Act
      final result = await repository.fetchMaterialCatalog(categoryId: 3);

      // Assert
      expect(result, hasLength(1));
      expect(result.single.name, 'Cerámica esmaltada 30x30');
    });

    test(
        'devuelve un estado vacío cuando la categoría no tiene catálogo todavía',
        () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>(
          '/material-catalog',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/material-catalog'),
          data: {
            'data': <dynamic>[],
            'pagination': {
              'total': 0,
              'page': 1,
              'pageSize': 100,
              'totalPages': 0,
            },
          },
        ),
      );

      // Act
      final result = await repository.fetchMaterialCatalog(categoryId: 99);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('replaceBudgetOptions', () {
    test('manda las opciones como {options: [...]} y mapea la respuesta',
        () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'data': [budgetOptionJson()],
          },
        ),
      );
      final draft = BudgetOptionDraft(
        label: 'Estándar',
        lineItems: [
          BudgetLineItemDraft(
            itemType: BudgetLineItemType.material,
            catalogItemReferenceId: 'catalog-1',
            description: 'Cerámica esmaltada 30x30',
            quantity: 10,
            unitPrice: 45000,
          ),
        ],
      );

      // Act
      final result = await repository.replaceBudgetOptions(
        'service-1',
        'request-1',
        [draft],
      );

      // Assert
      expect(result, hasLength(1));
      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      final sentOptions = captured['options'] as List<dynamic>;
      expect(sentOptions, hasLength(1));
      expect(
        (sentOptions.single as Map<String, dynamic>)['catalogItemReferenceId'],
        isNull,
      );
    });

    test(
        'lanza BudgetValidationFailure con el mensaje del backend cuando se excede el máximo',
        () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        validationError(
          '/services/service-1/requests/request-1/budget-options',
          message: 'Se permiten como máximo 3 opciones',
        ),
      );

      // Act & Assert
      await expectLater(
        repository.replaceBudgetOptions('service-1', 'request-1', []),
        throwsA(
          isA<BudgetValidationFailure>().having(
            (failure) => failure.backendMessage,
            'backendMessage',
            'Se permiten como máximo 3 opciones',
          ),
        ),
      );
    });
  });

  group('selectBudgetOption', () {
    test('devuelve la opción seleccionada', () async {
      // Arrange
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options/option-1/select',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: budgetOptionJson(isSelected: true),
        ),
      );

      // Act
      final result = await repository.selectBudgetOption(
        'service-1',
        'request-1',
        'option-1',
      );

      // Assert
      expect(result.isSelected, isTrue);
    });

    test(
        'lanza BudgetConflictFailure en 409 (el servicio ya no acepta propuestas)',
        () async {
      // Arrange
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options/option-1/select',
        ),
      ).thenThrow(
        conflictError(
          '/services/service-1/requests/request-1/budget-options/option-1/select',
        ),
      );

      // Act & Assert
      await expectLater(
        repository.selectBudgetOption('service-1', 'request-1', 'option-1'),
        throwsA(isA<BudgetConflictFailure>()),
      );
    });
  });
}
