import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/contracts/models/contract.dart';
import 'package:tekoapp_mobile/features/contracts/models/contract_status.dart';

void main() {
  Map<String, dynamic> contractJson({
    List<Map<String, dynamic>> lineItems = const [],
    Map<String, dynamic>? legalTermsVersion,
  }) {
    return {
      'referenceId': 'contract-1',
      'status': 'PENDING_CLIENT_SIGNATURE',
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
        'lineItems': lineItems,
      },
      'legalTermsVersion': legalTermsVersion,
      'clientSignedAt': null,
      'professionalSignedAt': null,
      'pdfAvailable': false,
    };
  }

  group('Contract.fromJson — codegen (M-04)', () {
    test(
      'parsea contentSnapshot.lineItems con más de un ítem — primer array de '
      'objetos anidados que migra a codegen (v4 del generador)',
      () {
        final contract = Contract.fromJson(
          contractJson(
            lineItems: [
              {
                'itemType': 'MATERIAL',
                'catalogItemName': 'Pintura látex',
                'description': '2 baldes',
                'quantity': 2,
                'unitPrice': 80000,
                'subtotal': 160000,
              },
              {
                'itemType': 'LABOR',
                'catalogItemName': null,
                'description': 'Mano de obra',
                'quantity': 8,
                'unitPrice': 20000,
                'subtotal': 160000,
              },
            ],
          ),
        );

        expect(contract.contentSnapshot.lineItems, hasLength(2));
        expect(contract.contentSnapshot.lineItems[0].itemType, 'MATERIAL');
        expect(
          contract.contentSnapshot.lineItems[0].catalogItemName,
          'Pintura látex',
        );
        expect(contract.contentSnapshot.lineItems[1].catalogItemName, isNull);
        expect(contract.contentSnapshot.lineItems[1].subtotal, 160000);
      },
    );

    test('contentSnapshot.lineItems vacío parsea a lista vacía (no-regresión)',
        () {
      final contract = Contract.fromJson(contractJson());

      expect(contract.contentSnapshot.lineItems, isEmpty);
    });

    test('legalTermsVersion presente parsea el objeto anidado singular', () {
      final contract = Contract.fromJson(
        contractJson(
          legalTermsVersion: {
            'referenceId': 'terms-1',
            'version': '2026-08-01',
            'contentUrl': 'https://cdn.tekoapp.com.py/terms/2026-08-01.pdf',
          },
        ),
      );

      expect(contract.legalTermsVersion, isNotNull);
      expect(contract.legalTermsVersion!.version, '2026-08-01');
    });

    test('legalTermsVersion ausente (null) no crashea — sigue siendo opcional',
        () {
      final contract = Contract.fromJson(contractJson());

      expect(contract.legalTermsVersion, isNull);
    });

    test('status y viewerRole parsean vía los enums ya existentes del dominio',
        () {
      final contract = Contract.fromJson(contractJson());

      expect(contract.status, ContractStatus.pendingClientSignature);
      expect(contract.viewerRole, ContractViewerRole.client);
    });
  });

  group('MyContractSummary.fromJson — codegen (M-04)', () {
    test('parsea la fila de listado propio completa', () {
      final summary = MyContractSummary.fromJson({
        'referenceId': 'contract-1',
        'status': 'SIGNED',
        'serviceTitle': 'Pintura de living',
        'createdAt': '2026-08-28T10:00:00.000Z',
        'pdfAvailable': true,
      });

      expect(summary.referenceId, 'contract-1');
      expect(summary.status, ContractStatus.signed);
      expect(summary.serviceTitle, 'Pintura de living');
      expect(summary.pdfAvailable, isTrue);
    });
  });
}
