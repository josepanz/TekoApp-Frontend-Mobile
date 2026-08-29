import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/budgets/widgets/budget_comparison_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  final router = GoRouter(
    initialLocation: '/mis-servicios/service-1/solicitudes/request-1/presupuestos',
    routes: [
      GoRoute(
        path: '/mis-servicios/service-1/solicitudes/request-1/presupuestos',
        builder: (context, state) => const BudgetComparisonScreen(
          serviceId: 'service-1',
          requestId: 'request-1',
        ),
      ),
      GoRoute(
        path: '/contratos/:referenceId',
        builder: (context, state) => Scaffold(
          body: Text('Contrato ${state.pathParameters['referenceId']}'),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      child: MaterialApp.router(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
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
    'muestra un estado vacío cuando el profesional todavía no cargó opciones',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'data': <Map<String, dynamic>>[]},
        ),
      );

      // Act
      await _pumpScreen(tester, dio);

      // Assert
      expect(
        find.text('El profesional todavía no cargó opciones de presupuesto'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'elige una opción, genera el contrato y navega a su firma',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {
            'data': [
              {
                'referenceId': 'option-1',
                'label': 'Estándar',
                'description': null,
                'totalPrice': 450000,
                'estimatedHours': 8,
                'isSelected': false,
                'lineItems': <Map<String, dynamic>>[],
              },
            ],
          },
        ),
      );
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
            'totalPrice': 450000,
            'isSelected': true,
            'lineItems': <Map<String, dynamic>>[],
          },
        ),
      );
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
                'totalPrice': 450000,
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
      await _pumpScreen(tester, dio);
      expect(find.text('Estándar'), findsOneWidget);

      // Act
      await tester.tap(find.byKey(const Key('budget_option_select_option-1')));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => dio.patch<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options/option-1/select',
        ),
      ).called(1);
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/budget-options/option-1/generate-contract',
        ),
      ).called(1);
      expect(find.text('Contrato contract-1'), findsOneWidget);
    },
  );
}
