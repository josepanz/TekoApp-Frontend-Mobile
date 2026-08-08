import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/payments/widgets/payment_methods_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) {
  return tester.pumpWidget(
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
        home: PaymentMethodsScreen(),
      ),
    ),
  );
}

Map<String, dynamic> _methodJson({
  String id = 'pm-uuid-1',
  bool isDefault = false,
}) =>
    {
      'id': id,
      'name': 'Visa terminada en 4242',
      'type': 'CREDIT_CARD',
      'provider': 'STRIPE',
      'isDefault': isDefault,
      'isActive': true,
      'details': {'cardLast4': '4242'},
      'externalId': null,
    };

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  testWidgets('muestra un estado vacío cuando no hay métodos guardados', (
    tester,
  ) async {
    // Arrange
    when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: [],
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('Todavía no agregaste ningún método de pago'),
      findsOneWidget,
    );
  });

  testWidgets('muestra el badge de predeterminado en el método correcto', (
    tester,
  ) async {
    // Arrange
    when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: [_methodJson(isDefault: true)],
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Visa terminada en 4242'), findsOneWidget);
    expect(find.text('Predeterminado'), findsOneWidget);
  });

  testWidgets('marca un método como predeterminado', (tester) async {
    // Arrange
    when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: [_methodJson()],
      ),
    );
    when(
      () => dio.put<Map<String, dynamic>>(
        '/payments/methods/pm-uuid-1',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods/pm-uuid-1'),
        data: _methodJson(isDefault: true),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const Key('payment_method_set_default_pm-uuid-1')));
    await tester.pumpAndSettle();

    // Assert
    verify(
      () => dio.put<Map<String, dynamic>>(
        '/payments/methods/pm-uuid-1',
        data: any(named: 'data'),
      ),
    ).called(1);
  });

  testWidgets(
    'elimina un método tras confirmar el diálogo',
    (tester) async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/methods'),
          data: [_methodJson()],
        ),
      );
      when(
        () => dio.delete<void>('/payments/methods/pm-uuid-1'),
      ).thenAnswer(
        (_) async => Response<void>(
          requestOptions: RequestOptions(path: '/payments/methods/pm-uuid-1'),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('payment_method_delete_pm-uuid-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      // Assert
      verify(() => dio.delete<void>('/payments/methods/pm-uuid-1')).called(1);
    },
  );

  testWidgets(
    'muestra el mensaje EXACTO del backend cuando no se puede eliminar el único método',
    (tester) async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/methods'),
          data: [_methodJson()],
        ),
      );
      when(() => dio.delete<void>('/payments/methods/pm-uuid-1')).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/payments/methods/pm-uuid-1',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/payments/methods/pm-uuid-1',
            ),
            statusCode: 400,
            data: {
              'success': false,
              'error': {
                'code': 400,
                'message': 'No se puede eliminar el único método de pago',
              },
            },
          ),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();
      await tester
          .tap(find.byKey(const Key('payment_method_delete_pm-uuid-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar').last);
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('No se puede eliminar el único método de pago'),
        findsOneWidget,
      );
    },
  );
}
