import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/core/mode/app_mode.dart';
import 'package:tekoapp_mobile/core/mode/app_mode_provider.dart';
import 'package:tekoapp_mobile/features/home/widgets/home_screen.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

const _profile = ProfessionalProfile(
  id: 2,
  referenceId: 'prof-uuid-1',
  categoryId: 3,
  description: 'Plomero',
  hourlyRate: 50000,
  status: ProfessionalStatus.approved,
  isAvailable: true,
  isOnline: false,
);

const _user = UserSummary(
  referenceId: 'ref-1',
  email: 'a@b.com',
  firstName: 'Ana',
  lastName: 'Pérez',
);

/// `sessionProvider` real llama a `flutter_secure_storage` al construirse — mismo motivo que en
/// `test/app_redirect_test.dart`, se fija un estado sincrónico para no depender de un mock de
/// plataforma.
class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this._fixed);
  final SessionState _fixed;

  @override
  SessionState build() => _fixed;
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  ProfessionalProfile? professionalProfile,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/solicitar',
        builder: (context, state) =>
            const Scaffold(body: Text('pantalla-solicitar')),
      ),
      GoRoute(
        path: '/mapa/cercanos',
        builder: (context, state) =>
            const Scaffold(body: Text('pantalla-mapa')),
      ),
      GoRoute(
        path: '/mis-servicios',
        builder: (context, state) =>
            const Scaffold(body: Text('pantalla-mis-servicios')),
      ),
      GoRoute(
        path: '/pagos/metodos',
        builder: (context, state) =>
            const Scaffold(body: Text('pantalla-metodos-pago')),
      ),
      GoRoute(
        path: '/pagos/historial',
        builder: (context, state) =>
            const Scaffold(body: Text('pantalla-historial-pagos')),
      ),
      GoRoute(
        path: '/profesional',
        builder: (context, state) =>
            const Scaffold(body: Text('pantalla-profesional')),
      ),
      GoRoute(
        path: '/profesional/onboarding',
        builder: (context, state) =>
            const Scaffold(body: Text('pantalla-onboarding-profesional')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(
          () => _FixedSessionNotifier(const SessionAuthenticated(_user)),
        ),
        myProfessionalProfileProvider.overrideWith(
          (ref) => Future.value(professionalProfile),
        ),
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

void main() {
  testWidgets('muestra el saludo con el nombre del usuario autenticado', (
    tester,
  ) async {
    // Arrange & Act
    await _pumpScreen(tester);

    // Assert
    expect(find.text('Hola, Ana'), findsOneWidget);
  });

  testWidgets('cero artefactos de debug de la Fase 0001 visibles', (
    tester,
  ) async {
    // Arrange & Act
    await _pumpScreen(tester);

    // Assert
    expect(find.text('Próximamente'), findsNothing);
    expect(find.textContaining('países cargados'), findsNothing);
  });

  testWidgets('la tarjeta de "pedir servicio" navega a /solicitar', (
    tester,
  ) async {
    // Arrange
    await _pumpScreen(tester);

    // Act
    await tester.tap(find.byKey(const Key('home_request_service_button')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('pantalla-solicitar'), findsOneWidget);
  });

  testWidgets(
    'los accesos rápidos del grid navegan a sus rutas correspondientes',
    (tester) async {
      // Arrange
      await _pumpScreen(tester);

      // Act & Assert — mapa de cercanos
      await tester.tap(find.byKey(const Key('home_nearby_map_button')));
      await tester.pumpAndSettle();
      expect(find.text('pantalla-mapa'), findsOneWidget);
    },
  );

  testWidgets('el ícono de modo profesional cambia el modo y navega', (
    tester,
  ) async {
    // Arrange
    await _pumpScreen(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );

    // Act
    await tester.tap(find.byKey(const Key('home_professional_mode_button')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('pantalla-profesional'), findsOneWidget);
    expect(container.read(appModeProvider), AppMode.professional);
  });

  testWidgets(
    'muestra el CTA de reclutamiento cuando el usuario no es profesional',
    (tester) async {
      // Arrange & Act
      await _pumpScreen(tester);

      // Assert
      expect(find.text('¿Querés trabajar con nosotros?'), findsOneWidget);
      expect(find.text('Postulate como profesional'), findsOneWidget);
    },
  );

  testWidgets(
    'el CTA de reclutamiento cambia el modo y navega al onboarding profesional',
    (tester) async {
      // Arrange
      await _pumpScreen(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );

      // Act
      final ctaFinder = find.byKey(const Key('home_recruit_professional_cta'));
      await tester.ensureVisible(ctaFinder);
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('pantalla-onboarding-profesional'), findsOneWidget);
      expect(container.read(appModeProvider), AppMode.professional);
    },
  );

  testWidgets(
    'oculta el CTA de reclutamiento cuando el usuario ya es profesional',
    (tester) async {
      // Arrange & Act
      await _pumpScreen(tester, professionalProfile: _profile);

      // Assert
      expect(find.text('¿Querés trabajar con nosotros?'), findsNothing);
    },
  );
}
