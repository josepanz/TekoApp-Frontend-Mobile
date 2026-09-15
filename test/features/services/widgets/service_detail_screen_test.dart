import 'dart:async';

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
import 'package:tekoapp_mobile/core/realtime/locations_socket_service.dart';
import 'package:tekoapp_mobile/features/budgets/widgets/budget_comparison_screen.dart';
import 'package:tekoapp_mobile/features/locations/providers/locations_socket_provider.dart';
import 'package:tekoapp_mobile/features/services/widgets/service_detail_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

/// Doble de `LocationsSocketService` cuyo `connectionState` el test controla a mano — permite
/// ejercitar el aviso de M-03 (`_AssignedProfessionalTrackingSection`) sin tocar un socket real.
class _FakeLocationsSocketService implements LocationsSocketService {
  final connectionStateController =
      StreamController<LocationsSocketConnectionState>.broadcast();

  @override
  Stream<LocationsSocketConnectionState> get connectionState =>
      connectionStateController.stream;

  @override
  void connect(String accessToken) {}

  @override
  void disconnect() {}

  @override
  void emitUpdateLocation({
    required double latitude,
    required double longitude,
  }) {}

  @override
  void onLocationUpdated(void Function(ProfessionalLocationUpdate) listener) {}
}

/// Sin token: el tracking en vivo del profesional asignado (`assignedProfessionalLocationProvider`)
/// corta antes de tocar el socket real — evita que estos tests toquen el `MethodChannel` real de
/// `flutter_secure_storage`.
///
/// `GoRouter` real (no `MaterialApp` simple): "Ver presupuestos" navega con `context.push` a
/// `BudgetComparisonScreen` (Fase 0009).
Future<void> _pumpScreen(
  WidgetTester tester,
  _MockDio dio, {
  List<Override> extraOverrides = const [],
}) {
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
        ...extraOverrides,
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

  /// Ver `test/features/professional_profile/data/professional_profile_repository_test.dart`
  /// para el mismo fixture — `referenceId` coincide con `professional.referenceId` de
  /// `inProgressServiceJson()`/`completedServiceJson()` (`prof-uuid-1`), así
  /// `ClientContactSection` reconoce a quien mira la pantalla como el profesional asignado.
  Map<String, dynamic> myProfessionalProfileJson() {
    return {
      'id': 2,
      'referenceId': 'prof-uuid-1',
      'userId': 20,
      'categoryId': 3,
      'description': 'Plomero con 5 años de experiencia',
      'hourlyRate': 50000,
      'fixedRate': null,
      'skills': ['soldadura'],
      'certifications': <String>[],
      'yearsOfExperience': 5,
      'status': 'APPROVED',
      'isAvailable': true,
      'isOnline': true,
      'verificationStatus': 'VERIFIED',
      'requiredDocumentsVerified': true,
      'totalServices': 10,
      'averageRating': 4.5,
      'totalRatings': 8,
      'createdAt': '2026-01-01T00:00:00.000Z',
      'user': {
        'id': 20,
        'email': 'ana@example.com',
        'firstName': 'Ana',
        'lastName': 'Pérez',
      },
      'category': {'id': 3, 'name': 'Plomería', 'slug': 'plomeria'},
    };
  }

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
          'images': <String>[],
          'isUrgent': false,
          'createdAt': '2026-08-08T10:00:00.000Z',
          'users': {
            'id': 10,
            'referenceId': 'client-uuid-1',
            'firstName': 'María',
            'lastName': 'López',
            'email': 'maria@example.com',
          },
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
            'images': <String>[],
            'isUrgent': false,
            'createdAt': '2026-08-08T10:00:00.000Z',
            'users': {
              'id': 10,
              'referenceId': 'client-uuid-1',
              'firstName': 'María',
              'lastName': 'López',
              'email': 'maria@example.com',
            },
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

  Map<String, dynamic> inProgressServiceJson() {
    return {
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
      'images': <String>[],
      'isUrgent': false,
      'createdAt': '2026-08-08T10:00:00.000Z',
      'users': {
        'id': 10,
        'referenceId': 'client-uuid-1',
        'firstName': 'María',
        'lastName': 'López',
        'email': 'maria@example.com',
      },
      'professional': {
        'id': 2,
        'referenceId': 'prof-uuid-1',
        'user': {'firstName': 'Ana', 'lastName': 'Pérez'},
      },
    };
  }

  testWidgets(
    'avisa cuando se pierde la conexión del socket de ubicación y vuelve a la '
    'normalidad al reconectar (M-03)',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: inProgressServiceJson(),
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
      final socket = _FakeLocationsSocketService();

      // Act
      await _pumpScreen(
        tester,
        dio,
        extraOverrides: [
          locationsSocketServiceProvider.overrideWithValue(socket),
        ],
      );
      await tester.pumpAndSettle();

      // Assert — todavía no hubo ningún evento de estado, sin aviso.
      expect(find.text('Se perdió la conexión, reintentando…'), findsNothing);

      // Act — se cae la conexión.
      socket.connectionStateController.add(
        LocationsSocketConnectionState.reconnecting,
      );
      await tester.pump();
      await tester.pump();

      // Assert
      expect(
        find.text('Se perdió la conexión, reintentando…'),
        findsOneWidget,
      );

      // Act — reconecta.
      socket.connectionStateController.add(
        LocationsSocketConnectionState.connected,
      );
      await tester.pump();
      await tester.pump();

      // Assert — vuelve a la normalidad sola.
      expect(find.text('Se perdió la conexión, reintentando…'), findsNothing);
    },
  );

  testWidgets(
    'muestra un aviso persistente cuando el socket agota los reintentos (M-03)',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: inProgressServiceJson(),
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
      final socket = _FakeLocationsSocketService();

      // Act
      await _pumpScreen(
        tester,
        dio,
        extraOverrides: [
          locationsSocketServiceProvider.overrideWithValue(socket),
        ],
      );
      await tester.pumpAndSettle();
      socket.connectionStateController.add(
        LocationsSocketConnectionState.error,
      );
      await tester.pump();
      await tester.pump();

      // Assert
      expect(
        find.text('No se pudo restablecer la conexión'),
        findsOneWidget,
      );
    },
  );

  group('contacto del cliente para el profesional asignado (Tarea 8)', () {
    Map<String, dynamic> serviceWithClientContactJson({
      String? clientEmail = 'maria@example.com',
      String? clientPhoneNumber = '+595981111111',
    }) {
      final json = inProgressServiceJson();
      json['users'] = {
        'id': 10,
        'referenceId': 'client-uuid-1',
        'firstName': 'María',
        'lastName': 'López',
        if (clientEmail != null) 'email': clientEmail,
        if (clientPhoneNumber != null) 'phoneNumber': clientPhoneNumber,
      };
      return json;
    }

    void stubLocationNotFound() {
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
    }

    testWidgets(
      'muestra el email y el teléfono del cliente cuando el profesional asignado mira la '
      'pantalla y el cliente comparte su contacto',
      (tester) async {
        // Arrange
        when(
          () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/services/service-uuid-1'),
            data: serviceWithClientContactJson(),
          ),
        );
        stubLocationNotFound();
        when(
          () => dio.get<Map<String, dynamic>>('/professionals/me'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/professionals/me'),
            data: myProfessionalProfileJson(),
          ),
        );

        // Act
        await _pumpScreen(tester, dio);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Contacto del cliente'), findsOneWidget);
        expect(find.text('maria@example.com'), findsOneWidget);
        expect(find.text('+595981111111'), findsOneWidget);
        expect(
          find.text('El cliente no compartió sus datos de contacto.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'muestra un aviso, sin un hueco vacío, cuando el cliente no comparte su contacto',
      (tester) async {
        // Arrange — el backend enmascara el contacto ELIMINANDO las claves del JSON (no las manda
        // en `null`), ver `services-response.helper.ts#maskContactIfNotShared`.
        when(
          () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/services/service-uuid-1'),
            data: serviceWithClientContactJson(
              clientEmail: null,
              clientPhoneNumber: null,
            ),
          ),
        );
        stubLocationNotFound();
        when(
          () => dio.get<Map<String, dynamic>>('/professionals/me'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/professionals/me'),
            data: myProfessionalProfileJson(),
          ),
        );

        // Act
        await _pumpScreen(tester, dio);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Contacto del cliente'), findsOneWidget);
        expect(
          find.text('El cliente no compartió sus datos de contacto.'),
          findsOneWidget,
        );
        expect(find.text('maria@example.com'), findsNothing);
      },
    );

    testWidgets(
      'no muestra la sección de contacto del cliente a quien NO es el profesional asignado',
      (tester) async {
        // Arrange — 404 en /professionals/me: quien mira la pantalla no tiene perfil profesional
        // (es el cliente viendo su propio servicio).
        when(
          () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/services/service-uuid-1'),
            data: serviceWithClientContactJson(),
          ),
        );
        stubLocationNotFound();
        when(
          () => dio.get<Map<String, dynamic>>('/professionals/me'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/professionals/me'),
            response: Response(
              requestOptions: RequestOptions(path: '/professionals/me'),
              statusCode: 404,
            ),
          ),
        );

        // Act
        await _pumpScreen(tester, dio);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Contacto del cliente'), findsNothing);
      },
    );
  });

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
      'images': <String>[],
      'isUrgent': false,
      'createdAt': '2026-08-08T10:00:00.000Z',
      'users': {
        'id': 10,
        'referenceId': 'client-uuid-1',
        'firstName': 'María',
        'lastName': 'López',
        'email': 'maria@example.com',
      },
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
      'images': <String>[],
      'isUrgent': false,
      'createdAt': '2026-08-08T10:00:00.000Z',
      'users': {
        'id': 10,
        'referenceId': 'client-uuid-1',
        'firstName': 'María',
        'lastName': 'López',
        'email': 'maria@example.com',
      },
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
              'isReported': false,
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
          'isReported': false,
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
