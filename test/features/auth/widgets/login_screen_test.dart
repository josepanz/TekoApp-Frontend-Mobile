import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tekoapp_mobile/core/auth/biometric_device_supported_provider.dart';
import 'package:tekoapp_mobile/features/auth/models/login_failure.dart';
import 'package:tekoapp_mobile/features/auth/providers/biometric_login_available_provider.dart';
import 'package:tekoapp_mobile/features/auth/providers/biometric_login_controller_provider.dart';
import 'package:tekoapp_mobile/features/auth/providers/biometric_opt_in_controller_provider.dart';
import 'package:tekoapp_mobile/features/auth/providers/login_controller_provider.dart';
import 'package:tekoapp_mobile/features/auth/widgets/login_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

/// Fija el estado inicial de `loginControllerProvider` sin pegarle a ningún repositorio — cada
/// test declara exactamente el estado que quiere ver renderizado.
class _FixedLoginController extends LoginController {
  _FixedLoginController({this.error, this.loading = false});

  final Object? error;
  final bool loading;

  @override
  FutureOr<void> build() {
    if (loading) {
      return Completer<void>().future; // nunca resuelve durante el test
    }
    if (error != null) {
      throw error!;
    }
    return null;
  }
}

/// Simula el ciclo de vida real de `LoginController.submit()` (loading → éxito) sin pegarle a
/// ningún repositorio — necesario para probar `_handleLoginSuccess` (el opt-in biométrico), que
/// se dispara en la transición `loading→éxito` de `ref.listen`, no en el estado inicial.
class _TransitionableLoginController extends LoginController {
  @override
  FutureOr<void> build() => null;

  Future<void> simulateSuccessfulLogin() async {
    state = const AsyncLoading();
    await Future<void>.delayed(Duration.zero);
    state = const AsyncData(null);
  }
}

/// Mismo patrón que `_FixedLoginController`, para `biometricLoginControllerProvider` — este
/// archivo solo necesita fijar un error (nunca loading), a diferencia de su equivalente de login
/// normal.
class _FixedBiometricLoginController extends BiometricLoginController {
  _FixedBiometricLoginController({required this.error});

  final Object error;

  @override
  FutureOr<void> build() => throw error;
}

/// Mismo patrón que `_FixedLocaleController` — `biometricOptInControllerProvider` es un
/// `AsyncNotifierProvider`, no un `FutureProvider`: su override espera una factory de notifier,
/// no un builder basado en `ref`.
class _FixedBiometricOptInController extends BiometricOptInController {
  _FixedBiometricOptInController(this._fixed);
  final bool _fixed;

  @override
  Future<bool> build() async => _fixed;
}

/// Espía de `biometricLoginControllerProvider.submit()` — no ejecuta el flujo real (biometría +
/// repositorio), solo registra que se llamó y con qué texto.
class _SpyBiometricLoginController extends BiometricLoginController {
  bool submitCalled = false;
  String? receivedReason;

  @override
  FutureOr<void> build() {}

  @override
  Future<void> submit({required String localizedReason}) async {
    submitCalled = true;
    receivedReason = localizedReason;
  }
}

Future<void> pumpLoginScreen(
  WidgetTester tester, {
  Object? error,
  bool loading = false,
  List<Override> extraOverrides = const [],
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _FixedLoginController(error: error, loading: loading),
        ),
        // Default seguro: `BiometricLoginService` real llama a `local_auth`, que no tiene
        // implementación de plataforma bajo `flutter test` — sin este override, el canal se
        // queda esperando una respuesta que nunca llega (comprobado en la práctica: no lanza,
        // así que ni un `try/catch` lo atrapa). Un test que sí quiera ejercitar la disponibilidad
        // real puede pisar este default agregando el suyo a `extraOverrides`.
        biometricDeviceSupportedProvider.overrideWith((ref) async => false),
        ...extraOverrides,
      ],
      child: const MaterialApp(
        // Fijar el locale explícito — el binding de test por default resuelve a `en`
        // (`Locale('en')` sí matchea `supportedLocales`), y estas aserciones esperan español.
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'muestra errores de validación al enviar el formulario vacío',
    (tester) async {
      // Arrange
      await pumpLoginScreen(tester);

      // Act
      await tester.tap(find.text('Ingresar'));
      await tester.pump();

      // Assert
      expect(find.text('Ingresá tu email'), findsOneWidget);
      expect(find.text('Ingresá tu contraseña'), findsOneWidget);
    },
  );

  testWidgets(
    'muestra el mensaje de credenciales inválidas',
    (tester) async {
      // Arrange & Act
      await pumpLoginScreen(tester, error: const InvalidCredentialsFailure());

      // Assert
      expect(find.text('Email o contraseña incorrectos'), findsOneWidget);
    },
  );

  testWidgets(
    'muestra el mensaje de sin conexión',
    (tester) async {
      // Arrange & Act
      await pumpLoginScreen(tester, error: const NoConnectionFailure());

      // Assert
      expect(
        find.text('Sin conexión — revisá tu internet e intentá de nuevo'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'muestra el mensaje de servicio no disponible',
    (tester) async {
      // Arrange & Act
      await pumpLoginScreen(tester, error: const ServiceUnavailableFailure());

      // Assert
      expect(
        find.text(
          'El servicio no está disponible — intentá de nuevo en unos minutos',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'deshabilita el formulario y muestra el spinner mientras carga',
    (tester) async {
      // Arrange & Act
      await pumpLoginScreen(tester, loading: true);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );

  group('login biométrico', () {
    testWidgets(
      'no muestra el botón biométrico cuando no está disponible (default)',
      (tester) async {
        // Arrange & Act — `pumpLoginScreen` ya fija `biometricDeviceSupportedProvider` en
        // `false` por default (ver el helper), que es el valor real que produciría
        // `BiometricLoginService.canAuthenticate()` en cualquier dispositivo sin biometría
        // enrolada.
        await pumpLoginScreen(tester);
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.byKey(const Key('login_biometric_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'muestra el botón biométrico cuando está disponible',
      (tester) async {
        // Arrange & Act
        await pumpLoginScreen(
          tester,
          extraOverrides: [
            biometricLoginAvailableProvider.overrideWith((ref) async => true),
          ],
        );
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.byKey(const Key('login_biometric_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tocar el botón biométrico llama a submit() del controller',
      (tester) async {
        // Arrange
        final spy = _SpyBiometricLoginController();
        await pumpLoginScreen(
          tester,
          extraOverrides: [
            biometricLoginAvailableProvider.overrideWith((ref) async => true),
            biometricLoginControllerProvider.overrideWith(() => spy),
          ],
        );
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byKey(const Key('login_biometric_button')));
        await tester.pump();

        // Assert
        expect(spy.submitCalled, isTrue);
        expect(
          spy.receivedReason,
          'Confirmá tu identidad para ingresar a TekoApp',
        );
      },
    );

    testWidgets(
      'muestra el error cuando falla el login biométrico',
      (tester) async {
        // Arrange & Act
        await pumpLoginScreen(
          tester,
          extraOverrides: [
            biometricLoginAvailableProvider.overrideWith((ref) async => true),
            biometricLoginControllerProvider.overrideWith(
              () => _FixedBiometricLoginController(
                error: const InvalidCredentialsFailure(),
              ),
            ),
          ],
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Email o contraseña incorrectos'), findsOneWidget);
      },
    );

    testWidgets(
      'ofrece activar el opt-in tras un login normal exitoso si el dispositivo '
      'soporta biometría y todavía no estaba activo',
      (tester) async {
        // Arrange
        final transitionableController = _TransitionableLoginController();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              loginControllerProvider.overrideWith(
                () => transitionableController,
              ),
              biometricOptInControllerProvider.overrideWith(
                () => _FixedBiometricOptInController(false),
              ),
              biometricDeviceSupportedProvider.overrideWith(
                (ref) async => true,
              ),
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
              home: LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Act — simula que `LoginController.submit()` completó con éxito.
        unawaited(transitionableController.simulateSuccessfulLogin());
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('¿Activar ingreso con huella/rostro?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'NO ofrece el opt-in si el dispositivo no soporta biometría y navega '
      'a home igual',
      (tester) async {
        // Arrange — acá SÍ hace falta un GoRouter real: al no ofrecerse el opt-in, el flujo
        // llega hasta el final de `_handleLoginSuccess` y ejecuta `context.go('/')` (a
        // diferencia del test de arriba, que queda colgado esperando el diálogo).
        final transitionableController = _TransitionableLoginController();
        final router = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: '/',
              builder: (context, state) => const Scaffold(body: Text('home')),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              loginControllerProvider.overrideWith(
                () => transitionableController,
              ),
              biometricOptInControllerProvider.overrideWith(
                () => _FixedBiometricOptInController(false),
              ),
              biometricDeviceSupportedProvider.overrideWith(
                (ref) async => false,
              ),
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
        await tester.pumpAndSettle();

        // Act
        unawaited(transitionableController.simulateSuccessfulLogin());
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('¿Activar ingreso con huella/rostro?'),
          findsNothing,
        );
        expect(find.text('home'), findsOneWidget);
      },
    );
  });
}
