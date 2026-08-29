import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/core/auth/access_token_reader_provider.dart';
import 'package:tekoapp_mobile/features/budgets/widgets/budget_comparison_screen.dart';
import 'package:tekoapp_mobile/features/services/widgets/service_detail_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

/// Sin token: el tracking en vivo del profesional asignado (`assignedProfessionalLocationProvider`)
/// corta antes de tocar el socket real — evita que estos tests toquen el `MethodChannel` real de
/// `flutter_secure_storage`.
///
/// `GoRouter` real (no `MaterialApp` simple): "Ver presupuestos" navega con `context.push` a
/// `BudgetComparisonScreen` (Fase 0009).
Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const ServiceDetailScreen(serviceId: 'service-uuid-1'),
      ),
      GoRoute(
        path: '/mis-servicios/:id/solicitudes/:requestId/presupuestos',
        builder: (context, state) => BudgetComparisonScreen(
          serviceId: state.pathParameters['id']!,
          requestId: state.pathParameters['requestId']!,
        ),
      ),
    ],
  );

  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        accessTokenReaderProvider.overrideWithValue(() async => null),
      ],
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
}

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  testWidgets('muestra el detalle con el profesional asignado', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/service-uuid-1'),
        data: {
          'id': 1,
          'referenceId': 'service-uuid-1',
          'userId': 1,
          'professionalId': 2,
          'categoryId': 3,
          'serviceTypeId': 4,
          'title': 'Reparación de cañería',
          'description': 'Se necesita reparar una cañería rota',
          'status': 'ACCEPTED',
          'latitude': -25.2,
          'longitude': -57.5,
          'address': 'Av. España 1234',
          'isUrgent': false,
          'createdAt': '2026-08-08T10:00:00.000Z',
          'professional': {
            'id': 2,
            'referenceId': 'prof-uuid-1',
            'user': {'firstName': 'Ana', 'lastName': 'Pérez'},
          },
        },
      ),
    );
    when(
      () => dio.get<Map<String, dynamic>>('/locations/professional/2'),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/locations/professional/2'),
        response: Response(
          requestOptions: RequestOptions(path: '/locations/professional/2'),
          statusCode: 404,
        ),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Aceptado'), findsOneWidget);
    expect(find.text('Profesional asignado: Ana Pérez'), findsOneWidget);
    expect(
      find.byKey(const Key('assigned_professional_tracking_map')),
      findsNothing,
    );
  });

  testWidgets(
    'muestra el mapa en vivo del profesional asignado cuando ya compartió ubicación',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: {
            'id': 1,
            'referenceId': 'service-uuid-1',
            'userId': 1,
            'professionalId': 2,
            'categoryId': 3,
            'serviceTypeId': 4,
            'title': 'Reparación de cañería',
            'description': 'Se necesita reparar una cañería rota',
            'status': 'IN_PROGRESS',
            'latitude': -25.2,
            'longitude': -57.5,
            'address': 'Av. España 1234',
            'isUrgent': false,
            'createdAt': '2026-08-08T10:00:00.000Z',
            'professional': {
              'id': 2,
              'referenceId': 'prof-uuid-1',
              'user': {'firstName': 'Ana', 'lastName': 'Pérez'},
            },
          },
        ),
      );
      when(
        () => dio.get<Map<String, dynamic>>('/locations/professional/2'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/locations/professional/2'),
          data: {'latitude': -25.29, 'longitude': -57.62},
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.byKey(const Key('assigned_professional_tracking_map')),
        findsOneWidget,
      );
    },
  );

  testWidgets('muestra un error cuando falla la carga', (tester) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/services/service-uuid-1'),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.text('No se pudo cargar el servicio — intentá de nuevo'),
      findsOneWidget,
    );
  });

  Map<String, dynamic> pendingServiceJson() {
    return {
      'id': 1,
      'referenceId': 'service-uuid-1',
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
    };
  }

  testWidgets(
    'muestra un estado vacío de propuestas cuando el servicio está PENDING sin propuestas',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: pendingServiceJson(),
        ),
      );
      when(
        () => dio.get<Map<String, dynamic>>(
          '/services/service-uuid-1/requests',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/requests',
          ),
          data: {'data': <Map<String, dynamic>>[]},
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Todavía no recibiste propuestas'), findsOneWidget);
    },
  );

  testWidgets(
    'navega a comparar presupuestos de una propuesta competidora sobre mi servicio PENDING',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: pendingServiceJson(),
        ),
      );
      when(
        () => dio.get<Map<String, dynamic>>(
          '/services/service-uuid-1/requests',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/requests',
          ),
          data: {
            'data': [
              {
                'id': 1,
                'referenceId': 'request-uuid-1',
                'serviceId': 'service-uuid-1',
                'professionalId': 2,
                'status': 'PENDING',
                'createdAt': '2026-08-08T10:00:00.000Z',
              },
            ],
          },
        ),
      );
      when(
        () => dio.get<Map<String, dynamic>>(
          '/services/service-uuid-1/requests/request-uuid-1/budget-options',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          data: {'data': <Map<String, dynamic>>[]},
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();

      // Assert (propuesta visible antes de ver presupuestos)
      expect(find.text('Profesional #2'), findsOneWidget);

      // Act (ver presupuestos)
      await tester.tap(find.byKey(const Key('view_budgets_request-uuid-1')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Comparar presupuestos'), findsOneWidget);
    },
  );

  Map<String, dynamic> completedServiceJson() {
    return {
      'id': 1,
      'referenceId': 'service-uuid-1',
      'userId': 1,
      'professionalId': 2,
      'categoryId': 3,
      'serviceTypeId': 4,
      'title': 'Reparación de cañería',
      'description': 'Se necesita reparar una cañería rota',
      'status': 'COMPLETED',
      'latitude': -25.2,
      'longitude': -57.5,
      'address': 'Av. España 1234',
      'isUrgent': false,
      'createdAt': '2026-08-08T10:00:00.000Z',
      'professional': {
        'id': 2,
        'referenceId': 'prof-uuid-1',
        'user': {'firstName': 'Ana', 'lastName': 'Pérez'},
      },
    };
  }

  testWidgets(
    'ofrece calificar al profesional cuando el servicio está completado y no se calificó antes',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: completedServiceJson(),
        ),
      );
      when(
        () => dio.get<List<dynamic>>('/ratings/service/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/ratings/service/service-uuid-1',
          ),
          data: [],
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Calificar profesional'), findsOneWidget);
    },
  );

  testWidgets(
    'oculta el botón de calificar si ya existe una calificación cliente→profesional',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: completedServiceJson(),
        ),
      );
      when(
        () => dio.get<List<dynamic>>('/ratings/service/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/ratings/service/service-uuid-1',
          ),
          data: [
            {
              'id': 1,
              'referenceId': 'rating-uuid-1',
              'userId': 1,
              'professionalId': 2,
              'type': 'CLIENT_TO_PROFESSIONAL',
              'rating': 5,
              'review': null,
              'isAnonymous': false,
              'isActive': true,
              'createdAt': '2026-08-08T10:00:00.000Z',
            },
          ],
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Calificar profesional'), findsNothing);
    },
  );

  testWidgets('envía la calificación del profesional al confirmar el diálogo', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/service-uuid-1'),
        data: completedServiceJson(),
      ),
    );
    when(
      () => dio.get<List<dynamic>>('/ratings/service/service-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/ratings/service/service-uuid-1',
        ),
        data: [],
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>(
        '/ratings',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/ratings'),
        data: {
          'id': 1,
          'referenceId': 'rating-uuid-1',
          'userId': 1,
          'professionalId': 2,
          'type': 'CLIENT_TO_PROFESSIONAL',
          'rating': 5,
          'review': null,
          'isAnonymous': false,
          'isActive': true,
          'createdAt': '2026-08-08T10:00:00.000Z',
        },
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calificar profesional'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rate_star_5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rate_dialog_submit_button')));
    await tester.pumpAndSettle();

    // Assert
    final sentData = verify(
      () => dio.post<Map<String, dynamic>>(
        '/ratings',
        data: captureAny(named: 'data'),
      ),
    ).captured.single as Map<String, dynamic>;
    expect(sentData['professionalId'], 'prof-uuid-1');
    expect(sentData['rating'], 5.0);
    expect(find.text('Calificación enviada'), findsOneWidget);
  });
}
