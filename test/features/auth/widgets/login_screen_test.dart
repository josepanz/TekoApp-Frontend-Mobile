import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/auth/models/login_failure.dart';
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

Future<void> pumpLoginScreen(
  WidgetTester tester, {
  Object? error,
  bool loading = false,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        loginControllerProvider.overrideWith(
          () => _FixedLoginController(error: error, loading: loading),
        ),
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
}
