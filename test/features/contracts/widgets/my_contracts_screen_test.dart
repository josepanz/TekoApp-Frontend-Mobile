import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/contracts/widgets/my_contracts_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  final router = GoRouter(
    initialLocation: '/contratos',
    routes: [
      GoRoute(
        path: '/contratos',
        builder: (context, state) => const MyContractsScreen(),
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

  testWidgets('muestra un estado vacío cuando no hay contratos todavía', (
    tester,
  ) async {
    // Arrange
    when(() => dio.get<Map<String, dynamic>>('/contracts')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ''),
        data: {'data': <Map<String, dynamic>>[]},
      ),
    );

    // Act
    await _pumpScreen(tester, dio);

    // Assert
    expect(find.text('Todavía no tenés contratos'), findsOneWidget);
  });

  testWidgets('navega a la vista previa al tocar un contrato', (
    tester,
  ) async {
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
    await _pumpScreen(tester, dio);
    expect(find.text('Pintura de living'), findsOneWidget);

    // Act
    await tester.tap(find.byKey(const Key('my_contract_tile_contract-1')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Contrato contract-1'), findsOneWidget);
  });
}
