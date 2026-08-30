import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/auth/models/register_failure.dart';
import 'package:tekoapp_mobile/features/auth/providers/register_controller_provider.dart';
import 'package:tekoapp_mobile/features/auth/widgets/register_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

/// Fija el estado inicial de `registerControllerProvider` sin pegarle a ningún repositorio —
/// mismo patrón que `login_screen_test.dart`.
class _FixedRegisterController extends RegisterController {
  _FixedRegisterController({this.error, this.loading = false});

  final Object? error;
  final bool loading;

  @override
  FutureOr<void> build() {
    if (loading) {
      return Completer<void>().future;
    }
    if (error != null) {
      throw error!;
    }
    return null;
  }
}

Future<void> pumpRegisterScreen(
  WidgetTester tester, {
  Object? error,
  bool loading = false,
}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        registerControllerProvider.overrideWith(
          () => _FixedRegisterController(error: error, loading: loading),
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
        home: RegisterScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'muestra errores de validación al enviar el formulario vacío',
    (tester) async {
      // Arrange
      await pumpRegisterScreen(tester);

      // Act
      final submitButton = find.text('Crear cuenta').last;
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      // Assert
      expect(find.text('Ingresá tu nombre'), findsOneWidget);
      expect(find.text('Ingresá tu apellido'), findsOneWidget);
      expect(find.text('Ingresá tu email'), findsOneWidget);
      expect(find.text('Ingresá tu teléfono'), findsOneWidget);
      expect(
        find.text('Debés aceptar los términos y condiciones'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'muestra el mensaje de email ya registrado',
    (tester) async {
      // Arrange & Act
      await pumpRegisterScreen(
        tester,
        error: const EmailAlreadyRegisteredFailure(),
      );

      // Assert
      expect(find.text('Ese email ya está registrado'), findsOneWidget);
    },
  );

  testWidgets(
    'muestra el mensaje de sin conexión',
    (tester) async {
      // Arrange & Act
      await pumpRegisterScreen(
        tester,
        error: const RegisterNoConnectionFailure(),
      );

      // Assert
      expect(
        find.text('Sin conexión — revisá tu internet e intentá de nuevo'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'deshabilita el formulario y muestra el spinner mientras carga',
    (tester) async {
      // Arrange & Act
      await pumpRegisterScreen(tester, loading: true);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    },
  );
}
