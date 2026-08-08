import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/widgets/professional_services_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Map<String, dynamic> _serviceJson({
  required String id,
  required String status,
}) =>
    {
      'id': id,
      'userId': 1,
      'professionalId': 2,
      'categoryId': 3,
      'serviceTypeId': 4,
      'title': 'Reparación de cañería',
      'description': 'desc',
      'status': status,
      'latitude': -25.2,
      'longitude': -57.5,
      'address': 'Av. España 1234',
      'isUrgent': false,
      'createdAt': '2026-08-08T10:00:00.000Z',
    };

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
        home: ProfessionalServicesScreen(),
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

  testWidgets('muestra un estado vacío cuando no hay servicios asignados', (
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
    expect(find.text('Todavía no tenés servicios asignados'), findsOneWidget);
  });

  testWidgets('inicia un servicio ACCEPTED', (tester) async {
    // Arrange
    when(
      () => dio.get<List<dynamic>>(
        '/services/my-services',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/my-services'),
        data: [_serviceJson(id: 'service-uuid-1', status: 'ACCEPTED')],
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/start'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/service-uuid-1/start'),
        data: _serviceJson(id: 'service-uuid-1', status: 'IN_PROGRESS'),
      ),
    );
    await _pumpScreen(tester, dio);
    expect(find.text('Iniciar'), findsOneWidget);

    // Act
    await tester
        .tap(find.byKey(const Key('service_transition_service-uuid-1')));
    await tester.pumpAndSettle();

    // Assert
    verify(
      () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/start'),
    ).called(1);
  });

  testWidgets('completa un servicio IN_PROGRESS', (tester) async {
    // Arrange
    when(
      () => dio.get<List<dynamic>>(
        '/services/my-services',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/my-services'),
        data: [_serviceJson(id: 'service-uuid-1', status: 'IN_PROGRESS')],
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/complete'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/services/service-uuid-1/complete',
        ),
        data: _serviceJson(id: 'service-uuid-1', status: 'COMPLETED'),
      ),
    );
    await _pumpScreen(tester, dio);
    expect(find.text('Completar'), findsOneWidget);

    // Act
    await tester
        .tap(find.byKey(const Key('service_transition_service-uuid-1')));
    await tester.pumpAndSettle();

    // Assert
    verify(
      () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/complete'),
    ).called(1);
  });

  testWidgets(
    'muestra un mensaje de conflicto cuando el servicio ya cambió',
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
          data: [_serviceJson(id: 'service-uuid-1', status: 'ACCEPTED')],
        ),
      );
      when(
        () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/start'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/start',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/services/service-uuid-1/start',
            ),
            statusCode: 409,
          ),
        ),
      );
      await _pumpScreen(tester, dio);

      // Act
      await tester.tap(
        find.byKey(const Key('service_transition_service-uuid-1')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Esto cambió — actualizá la pantalla'), findsOneWidget);
    },
  );
}
