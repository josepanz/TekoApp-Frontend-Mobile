import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/payments/widgets/add_payment_method_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddPaymentMethodScreen(),
                  ),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  testWidgets(
    'muestra los errores de validación al confirmar sin completar nada',
    (tester) async {
      // Arrange
      await _pumpScreen(tester, dio);

      // Act
      await tester.ensureVisible(
        find.byKey(const Key('payment_method_form_submit_button')),
      );
      await tester.tap(
        find.byKey(const Key('payment_method_form_submit_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ingresá un nombre para identificarlo'), findsOneWidget);
      expect(find.text('Elegí un tipo'), findsOneWidget);
      expect(find.text('Elegí un proveedor'), findsOneWidget);
    },
  );

  testWidgets('crea el método con los datos completos y vuelve atrás', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>(
        '/payments/methods',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: {
          'id': 'pm-uuid-1',
          'name': 'Visa terminada en 4242',
          'type': 'CREDIT_CARD',
          'provider': 'STRIPE',
          'isDefault': false,
          'isActive': true,
          'details': <String, dynamic>{},
          'externalId': null,
        },
      ),
    );
    await _pumpScreen(tester, dio);

    // Act
    await tester.enterText(
      find.byKey(const Key('payment_method_name_field')),
      'Visa terminada en 4242',
    );
    await tester.tap(find.byKey(const Key('payment_method_type_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tarjeta de crédito').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment_method_provider_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stripe').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('payment_method_form_submit_button')),
    );
    await tester.tap(
      find.byKey(const Key('payment_method_form_submit_button')),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(AddPaymentMethodScreen), findsNothing);
  });

  testWidgets(
    'muestra un error genérico cuando el backend rechaza la creación',
    (tester) async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments/methods',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/payments/methods'),
          response: Response(
            requestOptions: RequestOptions(path: '/payments/methods'),
            statusCode: 400,
          ),
        ),
      );
      await _pumpScreen(tester, dio);

      // Act
      await tester.enterText(
        find.byKey(const Key('payment_method_name_field')),
        'Visa terminada en 4242',
      );
      await tester.tap(find.byKey(const Key('payment_method_type_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tarjeta de crédito').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payment_method_provider_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stripe').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('payment_method_form_submit_button')),
      );
      await tester.tap(
        find.byKey(const Key('payment_method_form_submit_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('No se pudo guardar — revisá los datos ingresados'),
        findsOneWidget,
      );
    },
  );
}
