import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/contracts/providers/generate_contract_controller_provider.dart';

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
    'genera el contrato y devuelve su referenceId para navegar a la firma',
    () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/budget-options/option-1/generate-contract',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'referenceId': 'contract-1',
            'status': 'PENDING_CLIENT_SIGNATURE',
            'viewerRole': 'CLIENT',
            'contentSnapshot': {
              'service': {
                'title': 'Pintura',
                'description': 'desc',
                'categoryName': 'Pintura',
              },
              'budgetOption': {
                'label': 'Estándar',
                'description': null,
                'totalPrice': 100000,
                'estimatedHours': null,
              },
              'lineItems': <Map<String, dynamic>>[],
            },
            'legalTermsVersion': null,
            'clientSignedAt': null,
            'professionalSignedAt': null,
            'pdfAvailable': false,
          },
        ),
      );

      // Act
      final contract = await container
          .read(generateContractControllerProvider.notifier)
          .generate('option-1');

      // Assert
      expect(contract?.referenceId, 'contract-1');
      final state = container.read(generateContractControllerProvider);
      expect(state.hasError, isFalse);
    },
  );

  test('deja null y estado con error cuando la generación falla', () async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>(
        '/budget-options/option-1/generate-contract',
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: ''),
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
        ),
      ),
    );

    // Act
    final contract = await container
        .read(generateContractControllerProvider.notifier)
        .generate('option-1');

    // Assert
    expect(contract, isNull);
    final state = container.read(generateContractControllerProvider);
    expect(state.hasError, isTrue);
  });
}
