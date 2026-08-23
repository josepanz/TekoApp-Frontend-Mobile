import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tekoapp_mobile/app.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/core/locale/locale_provider.dart';
import 'package:tekoapp_mobile/features/auth/widgets/login_screen.dart';
import 'package:tekoapp_mobile/features/categories/providers/categories_provider.dart';
import 'package:tekoapp_mobile/features/home/widgets/home_screen.dart';
import 'package:tekoapp_mobile/features/notifications/providers/push_messaging_provider.dart';
import 'package:tekoapp_mobile/features/notifications/providers/push_registration_controller.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart';
import 'package:tekoapp_mobile/features/professional_profile/widgets/professional_home_screen.dart';
import 'package:tekoapp_mobile/features/professional_profile/widgets/professional_onboarding_screen.dart';
import 'package:tekoapp_mobile/features/profile/widgets/profile_screen.dart';
import 'package:tekoapp_mobile/features/services/providers/available_services_provider.dart';

const _authenticatedUser = UserSummary(
  referenceId: 'ref-1',
  email: 'a@b.com',
  firstName: 'Ana',
  lastName: 'Pérez',
);

const _professionalProfile = ProfessionalProfile(
  id: 2,
  referenceId: 'prof-uuid-1',
  categoryId: 3,
  description: 'Plomero',
  hourlyRate: 50000,
  status: ProfessionalStatus.pending,
  isAvailable: false,
  isOnline: false,
);

/// `sessionProvider` real llama a `flutter_secure_storage` al construirse — sin mock de
/// plataforma en `flutter_test`, eso dispara una excepción de plugin no manejada (ver
/// `core/auth/session_provider.dart`). Se fija un estado sincrónico para no depender de eso; la
/// orquestación real de sesión tiene su propia suite (`test/core/auth/session_provider_test.dart`).
class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this._fixed);
  final SessionState _fixed;

  @override
  SessionState build() => _fixed;
}

/// Mismo motivo que `_FixedSessionNotifier` — `LocaleController` real llama a `SharedPreferences`.
class _FixedLocaleController extends LocaleController {
  _FixedLocaleController(this._fixed);
  Locale? _fixed;

  @override
  Future<Locale?> build() async => _fixed;

  @override
  Future<void> setLocale(Locale? locale) async {
    _fixed = locale;
    state = AsyncData(locale);
  }
}

/// `PushNotificationGateway` (montado por `TekoApp`) llama a `firebase_messaging` real en
/// `initState` — sin proyecto Firebase inicializado en `flutter test`, eso rompe cualquier test
/// que pumpee `TekoApp`. Mismo criterio que los fakes de arriba.
class _NoopPushRegistrationController extends PushRegistrationController {
  @override
  Future<void> registerIfPermitted() async {}

  @override
  Future<void> unregister() async {}
}

/// El smoke test de red (`networkSmokeCheckProvider`) tiene su propia suite mockeando dio (ver
/// test/core/api_client/network_smoke_check_provider_test.dart) — acá se sobreescribe para que
/// estos tests de redirección no dependan de una red real.
List<Override> _overridesWithSession(SessionState session) => [
      networkSmokeCheckProvider.overrideWith((ref) async => const []),
      sessionProvider.overrideWith(() => _FixedSessionNotifier(session)),
      localeControllerProvider.overrideWith(() => _FixedLocaleController(null)),
      onForegroundMessageProvider.overrideWithValue(() => const Stream.empty()),
      onMessageOpenedAppProvider.overrideWithValue(() => const Stream.empty()),
      initialPushMessageReaderProvider.overrideWithValue(() async => null),
      pushRegistrationControllerProvider.overrideWith(
        () => _NoopPushRegistrationController(),
      ),
    ];

void main() {
  testWidgets(
    'redirige a /login al navegar a una ruta protegida sin sesión',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overridesWithSession(const SessionUnauthenticated()),
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/perfil');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets(
    'no redirige al navegar a una ruta pública',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overridesWithSession(const SessionUnauthenticated()),
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/login');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets(
    'no redirige a una ruta protegida cuando la sesión está autenticada',
    (tester) async {
      // Arrange
      const user = UserSummary(
        referenceId: 'ref-1',
        email: 'a@b.com',
        firstName: 'Ana',
        lastName: 'Pérez',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overridesWithSession(const SessionAuthenticated(user)),
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/perfil');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProfileScreen), findsOneWidget);
    },
  );

  testWidgets(
    'no redirige a una ruta protegida ante servicio no disponible (nunca se trata como sin sesión)',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overridesWithSession(const SessionServiceUnavailable()),
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/perfil');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    },
  );

  testWidgets(
    'redirige a /profesional/onboarding cuando todavía no hay perfil profesional',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._overridesWithSession(
              const SessionAuthenticated(_authenticatedUser),
            ),
            myProfessionalProfileProvider.overrideWith((ref) async => null),
            // ProfessionalOnboardingScreen pide el catálogo de categorías — sin este override
            // pega a la red real (prohibido en tests, ver `.claude/rules/test.md`) y
            // `pumpAndSettle` nunca converge mientras el spinner de carga sigue animando.
            categoriesProvider.overrideWith((ref) async => const []),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/profesional');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProfessionalOnboardingScreen), findsOneWidget);
      expect(find.byType(ProfessionalHomeScreen), findsNothing);
    },
  );

  testWidgets(
    'no redirige a /profesional cuando ya existe un perfil profesional',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._overridesWithSession(
              const SessionAuthenticated(_authenticatedUser),
            ),
            myProfessionalProfileProvider.overrideWith(
              (ref) async => _professionalProfile,
            ),
            // Con perfil, ProfessionalHomeScreen muestra AvailableServicesScreen — sin este
            // override pega a la red real (prohibido en tests) y pumpAndSettle nunca converge.
            availableServicesProvider.overrideWith((ref) async => const []),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/profesional');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProfessionalHomeScreen), findsOneWidget);
      expect(find.byType(ProfessionalOnboardingScreen), findsNothing);
    },
  );

  testWidgets(
    'no redirige a /profesional ante servicio de perfiles no disponible',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._overridesWithSession(
              const SessionAuthenticated(_authenticatedUser),
            ),
            myProfessionalProfileProvider.overrideWith(
              (ref) async => throw Exception('servicio no disponible'),
            ),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/profesional');
      await tester.pumpAndSettle();

      // Assert — el gate deja pasar, la propia pantalla muestra su estado de error.
      expect(find.byType(ProfessionalHomeScreen), findsOneWidget);
      expect(find.byType(ProfessionalOnboardingScreen), findsNothing);
    },
  );
}
