import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/contracts/data/contracts_repository.dart';
import 'package:tekoapp_mobile/features/contracts/models/contract_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ContractsRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = ContractsRepository(ApiClient(dio: dio));
  });

  Map<String, dynamic> contractJson({String status = 'PENDING_CLIENT_SIGNATURE'}) {
    return {
      'referenceId': 'contract-1',
      'status': status,
      'viewerRole': 'CLIENT',
      'contentSnapshot': {
        'service': {
          'title': 'Pintura de living',
          'description': 'Pintar el living',
          'categoryName': 'Pintura',
        },
        'budgetOption': {
          'label': 'Estándar',
          'description': null,
          'totalPrice': 500000,
          'estimatedHours': null,
        },
        'lineItems': <Map<String, dynamic>>[],
      },
      'legalTermsVersion': null,
      'clientSignedAt': null,
      'professionalSignedAt': null,
      'pdfAvailable': false,
    };
  }

  test(
    'genera el contrato a partir de la opción de presupuesto seleccionada',
    () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/budget-options/option-1/generate-contract',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: contractJson(),
        ),
      );

      // Act
      final contract = await repository.generateContract('option-1');

      // Assert
      expect(contract.referenceId, 'contract-1');
    },
  );

  test('obtiene un contrato puntual', () async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/contracts/contract-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: contractJson(),
      ),
    );

    // Act
    final contract = await repository.fetchContract('contract-1');

    // Assert
    expect(contract.contentSnapshot.service.title, 'Pintura de living');
  });

  test('firma el contrato mandando el nombre completo y accepted:true', () async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>(
        '/contracts/contract-1/sign',
        data: {'fullName': 'Juan Pérez', 'accepted': true},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: contractJson(status: 'PENDING_PROFESSIONAL_SIGNATURE'),
      ),
    );

    // Act
    final contract = await repository.signContract('contract-1', 'Juan Pérez');

    // Assert
    expect(contract.referenceId, 'contract-1');
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

      // Act & Assert
      await expectLater(
        repository.signContract('contract-1', 'Juan Pérez'),
        throwsA(isA<ContractConflictFailure>()),
      );
    },
  );

  test('resuelve la URL presignada del PDF firmado', () async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/contracts/contract-1/pdf'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {'url': 'https://s3/presigned'},
      ),
    );

    // Act
    final url = await repository.fetchPdfUrl('contract-1');

    // Assert
    expect(url, 'https://s3/presigned');
  });

  test('lista los contratos propios', () async {
    // Arrange
    when(() => dio.get<Map<String, dynamic>>('/contracts')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {
          'data': [
            {
              'referenceId': 'contract-1',
              'status': 'SIGNED',
              'serviceTitle': 'Pintura de living',
              'createdAt': '2026-08-28T10:00:00.000Z',
              'pdfAvailable': true,
            },
          ],
        },
      ),
    );

    // Act
    final contracts = await repository.fetchMyContracts();

    // Assert
    expect(contracts, hasLength(1));
    expect(contracts.first.serviceTitle, 'Pintura de living');
  });
}
