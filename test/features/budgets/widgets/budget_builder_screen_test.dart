import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/budgets/widgets/budget_builder_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

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
        home: BudgetBuilderScreen(
          serviceId: 'service-1',
          requestId: 'request-1',
          categoryId: 3,
        ),
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

  void mockEmptyCatalog() {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/material-catalog',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/material-catalog'),
        data: {
          'data': <Map<String, dynamic>>[],
          'pagination': {
            'total': 0,
            'page': 1,
            'pageSize': 100,
            'totalPages': 0,
          },
        },
      ),
    );
  }

  testWidgets(
    'arranca con una opción "Estándar" aunque el catálogo de la categoría esté vacío todavía',
    (tester) async {
      // Arrange
      mockEmptyCatalog();

      // Act
      await _pumpScreen(tester, dio);

      // Assert
      expect(find.text('Estándar'), findsOneWidget);
      expect(
        find.byKey(const Key('budget_builder_submit_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'agrega un ítem libre a la opción y envía el presupuesto',
    (tester) async {
      // Arrange
      mockEmptyCatalog();
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
      await _pumpScreen(tester, dio);

      // Act
      await tester.tap(find.text('Agregar ítem'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción'),
        'Mano de obra',
      );
      final quantityField = find.widgetWithText(TextFormField, 'Cantidad');
      await tester.enterText(quantityField, '1');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('budget_builder_submit_button')));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => dio.put<Map<String, dynamic>>(
          '/services/service-1/requests/request-1/budget-options',
          data: any(named: 'data'),
        ),
      ).called(1);
    },
  );
}
