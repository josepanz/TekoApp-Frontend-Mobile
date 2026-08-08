import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/widgets/service_detail_screen.dart';
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
        home: ServiceDetailScreen(serviceId: 'service-uuid-1'),
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
          'id': 'service-uuid-1',
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

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Aceptado'), findsOneWidget);
    expect(find.text('Profesional asignado: Ana Pérez'), findsOneWidget);
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
}
