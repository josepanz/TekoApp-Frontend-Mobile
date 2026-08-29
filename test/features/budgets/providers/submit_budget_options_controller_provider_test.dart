import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/budgets/models/budget_failure.dart';
import 'package:tekoapp_mobile/features/budgets/models/budget_line_item_type.dart';
import 'package:tekoapp_mobile/features/budgets/models/budget_option.dart';
import 'package:tekoapp_mobile/features/budgets/providers/submit_budget_options_controller_provider.dart';

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

  List<BudgetOptionDraft> draftWithOneItem() => [
        BudgetOptionDraft(
          label: 'Estándar',
          lineItems: [
            BudgetLineItemDraft(
              itemType: BudgetLineItemType.labor,
              description: 'Mano de obra',
              quantity: 1,
              unitPrice: 100000,
            ),
          ],
        ),
      ];

  test('envía las opciones y queda en estado exitoso', () async {
    // Arrange
    when(
      () => dio.put<Map<String, dynamic>>(
        '/services/service-1/requests/request-1/budget-options',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {'data': <Map<String, dynamic>>[]},
      ),
    );

    // Act
    await container
        .read(submitBudgetOptionsControllerProvider.notifier)
        .submit('service-1', 'request-1', draftWithOneItem());

    // Assert
    final state = container.read(submitBudgetOptionsControllerProvider);
    expect(state.hasError, isFalse);
  });

  test(
    'deja un BudgetValidationFailure cuando se excede el máximo de opciones de la categoría',
    () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 400,
            data: {
              'error': {'message': 'Se permiten como máximo 3 opciones'},
            },
          ),
        ),
      );

      // Act
      await container
          .read(submitBudgetOptionsControllerProvider.notifier)
          .submit('service-1', 'request-1', draftWithOneItem());

      // Assert
      final state = container.read(submitBudgetOptionsControllerProvider);
      expect(state.hasError, isTrue);
      expect(
        state.error,
        isA<BudgetValidationFailure>().having(
          (failure) => failure.backendMessage,
          'backendMessage',
          'Se permiten como máximo 3 opciones',
        ),
      );
    },
  );
}
