import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/budgets/models/budget_failure.dart';
import 'package:tekoapp_mobile/features/budgets/providers/select_budget_option_controller_provider.dart';

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

  test('elige la opción y queda en estado exitoso', () async {
    // Arrange
    when(
      () => dio.patch<Map<String, dynamic>>(
        '/services/service-1/requests/request-1/budget-options/option-1/select',
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'referenceId': 'option-1',
          'label': 'Estándar',
          'totalPrice': 100000,
          'isSelected': true,
          'lineItems': <Map<String, dynamic>>[],
        },
      ),
    );

    // Act
    await container
        .read(selectBudgetOptionControllerProvider.notifier)
        .select('service-1', 'request-1', 'option-1');

    // Assert
    final state = container.read(selectBudgetOptionControllerProvider);
    expect(state.hasError, isFalse);
  });

  test(
    'deja un BudgetConflictFailure (409) cuando el servicio ya no acepta propuestas',
    () async {
      // Arrange
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options/option-1/select',
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 409,
          ),
        ),
      );

      // Act
      await container
          .read(selectBudgetOptionControllerProvider.notifier)
          .select('service-1', 'request-1', 'option-1');

      // Assert
      final state = container.read(selectBudgetOptionControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<BudgetConflictFailure>());
    },
  );
}
