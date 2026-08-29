import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/contracts/models/contract_failure.dart';
import 'package:tekoapp_mobile/features/contracts/providers/sign_contract_controller_provider.dart';

class _MockDio extends Mock implements Dio {}

Map<String, dynamic> _contractJson(String status) {
  return {
    'referenceId': 'contract-1',
    'status': status,
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
    'pdfAvailable': status == 'SIGNED',
  };
}

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

  test('firma en orden correcto y queda en estado exitoso', () async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>(
        '/contracts/contract-1/sign',
        data: {'fullName': 'Juan Pérez', 'accepted': true},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: _contractJson('PENDING_PROFESSIONAL_SIGNATURE'),
      ),
    );

    // Act
    final contract = await container
        .read(signContractControllerProvider.notifier)
        .sign('contract-1', 'Juan Pérez');

    // Assert
    expect(contract?.status.name, 'pendingProfessionalSignature');
    final state = container.read(signContractControllerProvider);
    expect(state.hasError, isFalse);
  });

  test(
    'deja un ContractConflictFailure (409) al firmar dos veces o fuera de turno',
    () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/contracts/contract-1/sign',
          data: any(named: 'data'),
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
          .read(signContractControllerProvider.notifier)
          .sign('contract-1', 'Juan Pérez');

      // Assert
      final state = container.read(signContractControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ContractConflictFailure>());
    },
  );
}
