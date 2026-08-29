import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/core/location/current_location_provider.dart';
import 'package:tekoapp_mobile/features/categories/models/category.dart';
import 'package:tekoapp_mobile/features/categories/models/service_type.dart';
import 'package:tekoapp_mobile/features/categories/providers/categories_provider.dart';
import 'package:tekoapp_mobile/features/categories/providers/service_types_provider.dart';
import 'package:tekoapp_mobile/features/services/widgets/request_service_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

const _category = Category(
  id: 3,
  referenceId: 'cat-uuid',
  name: 'Plomería',
  slug: 'plomeria',
);
const _serviceType = ServiceType(id: 4, name: 'Instalación');

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _MockDio dio,
  required CurrentPositionFetcher locationFetcher,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        categoriesProvider.overrideWith((ref) async => [_category]),
        serviceTypesProvider.overrideWith((ref) async => [_serviceType]),
        currentPositionFetcherProvider.overrideWithValue(locationFetcher),
      ],
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
                    builder: (_) => const RequestServiceScreen(),
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
      await _pumpScreen(
        tester,
        dio: dio,
        locationFetcher: () async =>
            const DeviceLatLng(latitude: 0, longitude: 0),
      );

      // Act
      await tester.ensureVisible(
        find.byKey(const Key('request_service_submit_button')),
      );
      await tester.tap(find.byKey(const Key('request_service_submit_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Elegí una categoría'), findsOneWidget);
      expect(find.text('Elegí un tipo de servicio'), findsOneWidget);
      expect(find.text('Ingresá un título breve'), findsOneWidget);
      expect(
        find.text('Capturá tu ubicación antes de confirmar'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'muestra un error cuando el permiso de ubicación fue denegado',
    (tester) async {
      // Arrange
      await _pumpScreen(
        tester,
        dio: dio,
        locationFetcher: () async =>
            throw const LocationPermissionDeniedFailure(),
      );

      // Act
      await tester.tap(find.byKey(const Key('request_service_locate_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Necesitamos permiso de ubicación para continuar'),
        findsOneWidget,
      );
    },
  );

  testWidgets('crea el servicio con los datos completos y vuelve atrás', (
    tester,
  ) async {
    // Arrange
    when(
      () =>
          dio.post<Map<String, dynamic>>('/services', data: any(named: 'data')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services'),
        data: {
          'id': 1,
          'referenceId': 'service-uuid-1',
          'userId': 1,
          'professionalId': null,
          'categoryId': 3,
          'serviceTypeId': 4,
          'title': 'Reparación',
          'description': 'Necesito una reparación',
          'status': 'PENDING',
          'latitude': -25.2,
          'longitude': -57.5,
          'address': 'Calle 1',
          'isUrgent': false,
          'createdAt': '2026-08-08T10:00:00.000Z',
        },
      ),
    );
    await _pumpScreen(
      tester,
      dio: dio,
      locationFetcher: () async =>
          const DeviceLatLng(latitude: -25.2, longitude: -57.5),
    );

    // Act
    await tester.tap(find.byKey(const Key('request_service_category_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plomería').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('request_service_type_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instalación').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Reparación',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción'),
      'Necesito una reparación',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Dirección'),
      'Calle 1',
    );
    await tester.tap(find.byKey(const Key('request_service_locate_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('request_service_submit_button')),
    );
    await tester.tap(find.byKey(const Key('request_service_submit_button')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(RequestServiceScreen), findsNothing);
  });

  testWidgets(
    'muestra un error del backend cuando la creación falla',
    (tester) async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/services'),
          response: Response(
            requestOptions: RequestOptions(path: '/services'),
            statusCode: 400,
          ),
        ),
      );
      await _pumpScreen(
        tester,
        dio: dio,
        locationFetcher: () async =>
            const DeviceLatLng(latitude: -25.2, longitude: -57.5),
      );

      // Act
      await tester.tap(find.byKey(const Key('request_service_category_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plomería').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('request_service_type_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Instalación').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Reparación',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción'),
        'Necesito una reparación',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Dirección'),
        'Calle 1',
      );
      await tester.tap(find.byKey(const Key('request_service_locate_button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('request_service_submit_button')),
      );
      await tester.tap(find.byKey(const Key('request_service_submit_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Revisá los datos ingresados'), findsOneWidget);
    },
  );
}
