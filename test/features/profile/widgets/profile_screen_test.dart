import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/app.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';
import 'package:tekoapp_mobile/core/auth/biometric_device_supported_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/core/locale/locale_provider.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/features/auth/widgets/login_screen.dart';
import 'package:tekoapp_mobile/features/home/widgets/home_screen.dart';
import 'package:tekoapp_mobile/features/notifications/providers/push_messaging_provider.dart';
import 'package:tekoapp_mobile/features/notifications/providers/push_registration_controller.dart';
import 'package:tekoapp_mobile/features/profile/widgets/profile_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Ver `test/app_redirect_test.dart` — mismo motivo para fijar `sessionProvider` en vez de dejar
/// que resuelva solo.
class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this._fixed);
  final SessionState _fixed;

  @override
  SessionState build() => _fixed;
}

/// Mismo motivo — `LocaleController` real llama a `SharedPreferences`.
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

final _pushMessagingTestOverrides = <Override>[
  onForegroundMessageProvider.overrideWithValue(() => const Stream.empty()),
  onMessageOpenedAppProvider.overrideWithValue(() => const Stream.empty()),
  initialPushMessageReaderProvider.overrideWithValue(() async => null),
  pushRegistrationControllerProvider.overrideWith(
    () => _NoopPushRegistrationController(),
  ),
  // El test de logout termina de nuevo en `login_screen.dart`, que llama a
  // `BiometricLoginService` — el plugin real `local_auth` no tiene implementación de plataforma
  // bajo `flutter test`, y el canal se queda esperando una respuesta que nunca llega (no lanza,
  // así que ni un `try/catch` lo atrapa). Ver el mismo override en `login_screen_test.dart`.
  biometricDeviceSupportedProvider.overrideWith((ref) async => false),
];

void main() {
  testWidgets(
    'el botón de logout limpia la sesión y navega a /login',
    (tester) async {
      // Arrange
      final repository = _MockAuthRepository();
      when(() => repository.clearSession()).thenAnswer((_) async {});
      when(
        () => repository.hasBiometricCredentials(),
      ).thenAnswer((_) async => false);
      const user = UserSummary(
        referenceId: 'ref-1',
        email: 'a@b.com',
        firstName: 'Ana',
        lastName: 'Pérez',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkSmokeCheckProvider.overrideWith((ref) async => const []),
            localeControllerProvider.overrideWith(
              () => _FixedLocaleController(null),
            ),
            ..._pushMessagingTestOverrides,
            authRepositoryProvider.overrideWithValue(repository),
            sessionProvider.overrideWith(
              () => _FixedSessionNotifier(const SessionAuthenticated(user)),
            ),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/perfil');
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Act — se busca por Key, no por texto, para no depender del locale resuelto en el test
      // (el binding de flutter_test resuelve `en` por default, ver test/features/auth/widgets/
      // login_screen_test.dart para el mismo problema con un locale forzado en su lugar) ni de
      // qué otros botones tenga la pantalla. El selector de idioma agregado en la Fase 0006
      // empuja el botón fuera del viewport fijo de test — hay que scrollearlo a la vista.
      await tester
          .ensureVisible(find.byKey(const Key('profile_logout_button')));
      await tester.tap(find.byKey(const Key('profile_logout_button')));
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.clearSession()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets(
    'precarga los datos actuales del usuario en el formulario',
    (tester) async {
      // Arrange
      const user = UserSummary(
        referenceId: 'ref-1',
        email: 'ana@test.com',
        firstName: 'Ana',
        lastName: 'Pérez',
        phoneNumber: '+595981234567',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkSmokeCheckProvider.overrideWith((ref) async => const []),
            localeControllerProvider.overrideWith(
              () => _FixedLocaleController(null),
            ),
            ..._pushMessagingTestOverrides,
            sessionProvider.overrideWith(
              () => _FixedSessionNotifier(const SessionAuthenticated(user)),
            ),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/perfil');
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Pérez'), findsOneWidget);
      expect(find.text('+595981234567'), findsOneWidget);
      expect(find.text('ana@test.com'), findsOneWidget);
    },
  );

  testWidgets(
    'muestra un error de validación si se borra el nombre y se intenta guardar',
    (tester) async {
      // Arrange
      const user = UserSummary(
        referenceId: 'ref-1',
        email: 'ana@test.com',
        firstName: 'Ana',
        lastName: 'Pérez',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkSmokeCheckProvider.overrideWith((ref) async => const []),
            localeControllerProvider.overrideWith(
              () => _FixedLocaleController(null),
            ),
            ..._pushMessagingTestOverrides,
            sessionProvider.overrideWith(
              () => _FixedSessionNotifier(const SessionAuthenticated(user)),
            ),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/perfil');
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.text('Ana'), '');
      await tester.tap(find.byKey(const Key('profile_save_button')));
      await tester.pump();

      // Assert — no se fija el locale del test (`TekoApp` no expone un parámetro `locale` para
      // forzarlo desde afuera, ver test/features/auth/widgets/login_screen_test.dart para el
      // mismo problema resuelto ahí con un `MaterialApp` propio) — se acepta cualquiera de los 2
      // idiomas soportados en vez de asumir cuál resolvió el binding de test.
      final errorShown = find.text('Ingresá tu nombre').evaluate().isNotEmpty ||
          find.text('Enter your first name').evaluate().isNotEmpty;
      expect(errorShown, isTrue);
    },
  );

  testWidgets(
    'elegir English en el selector de idioma fuerza el idioma de toda la app',
    (tester) async {
      // Arrange
      const user = UserSummary(
        referenceId: 'ref-1',
        email: 'ana@test.com',
        firstName: 'Ana',
        lastName: 'Pérez',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkSmokeCheckProvider.overrideWith((ref) async => const []),
            localeControllerProvider.overrideWith(
              () => _FixedLocaleController(null),
            ),
            ..._pushMessagingTestOverrides,
            sessionProvider.overrideWith(
              () => _FixedSessionNotifier(const SessionAuthenticated(user)),
            ),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/perfil');
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(const Key('profile_language_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('My profile'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    },
  );

  group('switch de login biométrico', () {
    testWidgets(
      'aparece activado si ya hay credenciales guardadas, y desactivarlo las borra',
      (tester) async {
        // Arrange
        final repository = _MockAuthRepository();
        when(
          () => repository.hasBiometricCredentials(),
        ).thenAnswer((_) async => true);
        when(
          () => repository.clearBiometricCredentials(),
        ).thenAnswer((_) async {});
        const user = UserSummary(
          referenceId: 'ref-1',
          email: 'a@b.com',
          firstName: 'Ana',
          lastName: 'Pérez',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              networkSmokeCheckProvider.overrideWith((ref) async => const []),
              localeControllerProvider.overrideWith(
                () => _FixedLocaleController(null),
              ),
              ..._pushMessagingTestOverrides,
              authRepositoryProvider.overrideWithValue(repository),
              sessionProvider.overrideWith(
                () => _FixedSessionNotifier(const SessionAuthenticated(user)),
              ),
            ],
            child: const TekoApp(),
          ),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
        router.go('/perfil');
        await tester.pumpAndSettle();

        // Assert — arranca activado
        final switchKey = find.byKey(const Key('profile_biometric_switch'));
        await tester.ensureVisible(switchKey);
        expect(tester.widget<Switch>(switchKey).value, isTrue);

        // Act — lo desactiva
        await tester.tap(switchKey);
        await tester.pumpAndSettle();

        // Assert
        verify(() => repository.clearBiometricCredentials()).called(1);
        expect(tester.widget<Switch>(switchKey).value, isFalse);
      },
    );

    testWidgets(
      'aparece desactivado y sin poder tocarse si no hay credenciales guardadas',
      (tester) async {
        // Arrange
        final repository = _MockAuthRepository();
        when(
          () => repository.hasBiometricCredentials(),
        ).thenAnswer((_) async => false);
        const user = UserSummary(
          referenceId: 'ref-1',
          email: 'a@b.com',
          firstName: 'Ana',
          lastName: 'Pérez',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              networkSmokeCheckProvider.overrideWith((ref) async => const []),
              localeControllerProvider.overrideWith(
                () => _FixedLocaleController(null),
              ),
              ..._pushMessagingTestOverrides,
              authRepositoryProvider.overrideWithValue(repository),
              sessionProvider.overrideWith(
                () => _FixedSessionNotifier(const SessionAuthenticated(user)),
              ),
            ],
            child: const TekoApp(),
          ),
        );
        await tester.pumpAndSettle();
        final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
        router.go('/perfil');
        await tester.pumpAndSettle();

        // Assert — no se puede activar desde acá (ver docstring de `_BiometricLoginToggle`).
        final switchKey = find.byKey(const Key('profile_biometric_switch'));
        await tester.ensureVisible(switchKey);
        final switchWidget = tester.widget<Switch>(switchKey);
        expect(switchWidget.value, isFalse);
        expect(switchWidget.onChanged, isNull);
        verifyNever(() => repository.clearBiometricCredentials());
      },
    );
  });

  testWidgets(
    'el botón de eliminar cuenta navega a la pantalla de borrado, separado del logout',
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
          overrides: [
            networkSmokeCheckProvider.overrideWith((ref) async => const []),
            localeControllerProvider.overrideWith(
              () => _FixedLocaleController(null),
            ),
            ..._pushMessagingTestOverrides,
            sessionProvider.overrideWith(
              () => _FixedSessionNotifier(const SessionAuthenticated(user)),
            ),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/perfil');
      await tester.pumpAndSettle();

      // Act
      await tester.ensureVisible(
        find.byKey(const Key('profile_delete_account_button')),
      );
      await tester.tap(find.byKey(const Key('profile_delete_account_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.byKey(const Key('account_deletion_confirm_button')),
        findsOneWidget,
      );
    },
  );
}
