import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart';
import 'package:tekoapp_mobile/features/services/widgets/available_services_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

const _profile = ProfessionalProfile(
  id: 2,
  referenceId: 'prof-uuid-1',
  categoryId: 3,
  description: 'Plomero',
  hourlyRate: 50000,
  status: ProfessionalStatus.pending,
  isAvailable: false,
  isOnline: false,
);

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        myProfessionalProfileProvider.overrideWith((ref) async => _profile),
      ],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AvailableServicesScreen()),
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
    'muestra un estado vacío cuando no hay servicios disponibles',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>(
          '/services',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services'),
          data: {
            'data': <Map<String, dynamic>>[],
            'pagination': {
              'total': 0,
              'page': 1,
              'pageSize': 10,
              'totalPages': 0,
            },
          },
        ),
      );

      // Act
      await _pumpScreen(tester, dio);

      // Assert
      expect(
        find.text('No hay servicios disponibles en tu categoría por ahora'),
        findsOneWidget,
      );
    },
  );

  testWidgets('se propone sobre un servicio disponible', (tester) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>(
        '/services',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services'),
        data: {
          'data': [
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
          'pagination': {
            'total': 1,
            'page': 1,
            'pageSize': 10,
            'totalPages': 1,
          },
        },
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>(
        '/services/service-uuid-1/requests',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/services/service-uuid-1/requests',
        ),
        data: {
          'id': 'request-uuid-1',
          'serviceId': 'service-uuid-1',
          'professionalId': 2,
          'status': 'PENDING',
          'createdAt': '2026-08-08T10:00:00.000Z',
        },
      ),
    );
    await _pumpScreen(tester, dio);
    expect(find.text('Reparación de cañería'), findsOneWidget);

    // Act
    await tester.tap(find.byKey(const Key('propose_button_service-uuid-1')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Te propusiste para este servicio'), findsOneWidget);
  });
}
