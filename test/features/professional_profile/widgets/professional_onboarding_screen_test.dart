import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/categories/models/category.dart';
import 'package:tekoapp_mobile/features/categories/providers/categories_provider.dart';
import 'package:tekoapp_mobile/features/professional_profile/widgets/professional_onboarding_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

const _category = Category(
  id: 3,
  referenceId: 'cat-uuid',
  name: 'Plomería',
  slug: 'plomeria',
);

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  final router = GoRouter(
    initialLocation: '/profesional/onboarding',
    routes: [
      GoRoute(
        path: '/profesional',
        builder: (context, state) => const Scaffold(body: Text('profesional')),
      ),
      GoRoute(
        path: '/profesional/onboarding',
        builder: (context, state) => const ProfessionalOnboardingScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        categoriesProvider.overrideWith((ref) async => [_category]),
      ],
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

Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const Key('professional_onboarding_category_field')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Plomería').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Descripción de tus servicios'),
    'Reparaciones e instalaciones',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Tarifa por hora (Gs.)'),
    '50000',
  );
  await tester.ensureVisible(
    find.byKey(const Key('professional_onboarding_submit_button')),
  );
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
        find.byKey(const Key('professional_onboarding_submit_button')),
      );
      await tester.tap(
        find.byKey(const Key('professional_onboarding_submit_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Elegí una categoría'), findsOneWidget);
      expect(find.text('Contanos qué servicios ofrecés'), findsOneWidget);
      expect(find.text('Ingresá una tarifa por hora válida'), findsOneWidget);
    },
  );

  testWidgets('activa el perfil con los datos completos y navega', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>(
        '/professionals',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/professionals'),
        data: {
          'id': 2,
          'referenceId': 'prof-uuid-1',
          'categoryId': 3,
          'description': 'Reparaciones e instalaciones',
          'hourlyRate': 50000,
          'fixedRate': null,
          'skills': <String>[],
          'yearsOfExperience': null,
          'status': 'PENDING',
          'isAvailable': false,
          'isOnline': false,
        },
      ),
    );
    await _pumpScreen(tester, dio);

    // Act
    await _fillValidForm(tester);
    await tester.tap(
      find.byKey(const Key('professional_onboarding_submit_button')),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(ProfessionalOnboardingScreen), findsNothing);
    expect(find.text('profesional'), findsOneWidget);
  });

  testWidgets('muestra un error del backend cuando la activación falla', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.post<Map<String, dynamic>>(
        '/professionals',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/professionals'),
        response: Response(
          requestOptions: RequestOptions(path: '/professionals'),
          statusCode: 400,
        ),
      ),
    );
    await _pumpScreen(tester, dio);

    // Act
    await _fillValidForm(tester);
    await tester.tap(
      find.byKey(const Key('professional_onboarding_submit_button')),
    );
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Revisá los datos ingresados'), findsOneWidget);
  });
}
