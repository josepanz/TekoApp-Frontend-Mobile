import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/widgets/my_services_screen.dart';
import 'package:tekoapp_mobile/features/services/widgets/service_detail_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  final router = GoRouter(
    initialLocation: '/mis-servicios',
    routes: [
      GoRoute(
        path: '/mis-servicios',
        builder: (context, state) => const MyServicesScreen(),
      ),
      GoRoute(
        path: '/mis-servicios/:id',
        builder: (context, state) =>
            ServiceDetailScreen(serviceId: state.pathParameters['id']!),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('muestra un estado vacío cuando no hay servicios todavía', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<List<dynamic>>(
        '/services/my-services',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/my-services'),
        data: [],
      ),
    );

    // Act
    await _pumpScreen(tester, dio);

    // Assert
    expect(find.text('Todavía no pediste ningún servicio'), findsOneWidget);
  });

  testWidgets('muestra un error cuando falla la carga', (tester) async {
    // Arrange
    when(
      () => dio.get<List<dynamic>>(
        '/services/my-services',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/services/my-services'),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);

    // Assert
    expect(
      find.text('No se pudieron cargar tus servicios — intentá de nuevo'),
      findsOneWidget,
    );
  });

  testWidgets(
    'muestra la lista y navega al detalle al tocar un servicio',
    (tester) async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>(
          '/services/my-services',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/my-services'),
          data: [
            {
              'id': 'service-uuid-1',
              'userId': 1,
              'professionalId': null,
              'categoryId': 3,
              'serviceTypeId': 4,
              'title': 'Reparación de cañería',
              'description': 'desc',
              'status': 'PENDING',
              'latitude': -25.2,
              'longitude': -57.5,
              'address': 'Av. España 1234',
              'isUrgent': false,
              'createdAt': '2026-08-08T10:00:00.000Z',
            },
          ],
        ),
      );
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: {
            'id': 'service-uuid-1',
            'userId': 1,
            'professionalId': null,
            'categoryId': 3,
            'serviceTypeId': 4,
            'title': 'Reparación de cañería',
            'description': 'Se necesita reparar una cañería rota',
            'status': 'PENDING',
            'latitude': -25.2,
            'longitude': -57.5,
            'address': 'Av. España 1234',
            'isUrgent': false,
            'createdAt': '2026-08-08T10:00:00.000Z',
          },
        ),
      );

      // Act
      await _pumpScreen(tester, dio);

      // Assert (lista)
      expect(find.text('Reparación de cañería'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);

      // Act (navegar al detalle)
      await tester.tap(find.byKey(const Key('service_item_service-uuid-1')));
      await tester.pumpAndSettle();

      // Assert (detalle)
      expect(
        find.text('Se necesita reparar una cañería rota'),
        findsOneWidget,
      );
    },
  );
}
