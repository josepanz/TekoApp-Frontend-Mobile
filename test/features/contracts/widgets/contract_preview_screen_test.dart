import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/contracts/widgets/contract_preview_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Map<String, dynamic> _contractJson({
  required String status,
  required bool pdfAvailable,
}) {
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
    'pdfAvailable': pdfAvailable,
  };
}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ContractPreviewScreen(contractReferenceId: 'contract-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  testWidgets(
    'muestra el formulario de firma cuando le toca firmar al cliente',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/contracts/contract-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: _contractJson(
            status: 'PENDING_CLIENT_SIGNATURE',
            pdfAvailable: false,
          ),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);

      // Assert
      expect(find.text('Pendiente de tu firma'), findsOneWidget);
      expect(find.byKey(const Key('contract_accept_checkbox')), findsOneWidget);
      expect(find.byKey(const Key('contract_sign_button')), findsOneWidget);
    },
  );

  testWidgets(
    'no muestra el formulario de firma cuando le toca a la otra parte',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/contracts/contract-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: _contractJson(
            status: 'PENDING_PROFESSIONAL_SIGNATURE',
            pdfAvailable: false,
          ),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);

      // Assert
      expect(find.text('Pendiente de la firma de la otra parte'), findsOneWidget);
      expect(find.byKey(const Key('contract_sign_button')), findsNothing);
    },
  );

  testWidgets('ofrece descargar el PDF cuando está firmado por ambos', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/contracts/contract-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: _contractJson(status: 'SIGNED', pdfAvailable: true),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);

    // Assert
    expect(find.text('Firmado por ambos'), findsOneWidget);
    expect(
      find.byKey(const Key('contract_download_pdf_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('contract_sign_button')), findsNothing);
  });

  testWidgets(
    'habilita el botón de firmar recién con nombre completo y checkbox marcados',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/contracts/contract-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: _contractJson(
            status: 'PENDING_CLIENT_SIGNATURE',
            pdfAvailable: false,
          ),
        ),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/contracts/contract-1/sign',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: _contractJson(
            status: 'PENDING_PROFESSIONAL_SIGNATURE',
            pdfAvailable: false,
          ),
        ),
      );
      await _pumpScreen(tester, dio);

      // Act
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Escribí tu nombre completo para confirmar'),
        'Juan Pérez',
      );
      await tester.ensureVisible(find.byKey(const Key('contract_accept_checkbox')));
      await tester.tap(find.byKey(const Key('contract_accept_checkbox')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('contract_sign_button')));
      await tester.tap(find.byKey(const Key('contract_sign_button')));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/contracts/contract-1/sign',
          data: {'fullName': 'Juan Pérez', 'accepted': true},
        ),
      ).called(1);
    },
  );
}
