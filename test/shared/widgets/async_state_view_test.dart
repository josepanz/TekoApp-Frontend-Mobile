import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';
import 'package:tekoapp_mobile/shared/widgets/async_state_view.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('es')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AsyncStateView', () {
    testWidgets(
      'estado de error sin errorMessage muestra el texto traducido (nunca el español fijo)',
      (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(
            AsyncStateView<int>(
              isLoading: false,
              hasError: true,
              data: null,
              builder: (context, data) => Text('$data'),
            ),
            locale: const Locale('en'),
          ),
        );

        // Assert
        expect(find.text('An unexpected error occurred.'), findsOneWidget);
        expect(find.text('Ocurrió un error inesperado.'), findsNothing);
      },
    );

    testWidgets(
      'estado vacío sin emptyMessage muestra el texto traducido',
      (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(
            AsyncStateView<int>(
              isLoading: false,
              hasError: false,
              data: 0,
              isEmpty: true,
              builder: (context, data) => Text('$data'),
            ),
            locale: const Locale('en'),
          ),
        );

        // Assert
        expect(find.text('No data to display.'), findsOneWidget);
        expect(find.text('No hay datos para mostrar.'), findsNothing);
      },
    );

    testWidgets('con onRetry, el botón aparece y tocarlo invoca el callback', (
      tester,
    ) async {
      // Arrange
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          AsyncStateView<int>(
            isLoading: false,
            hasError: true,
            data: null,
            onRetry: () => retried = true,
            builder: (context, data) => Text('$data'),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      // Assert
      expect(retried, isTrue);
    });

    testWidgets(
      'sin onRetry, no aparece ningún botón (no-regresión de las pantallas que no lo pasan)',
      (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          _wrap(
            AsyncStateView<int>(
              isLoading: false,
              hasError: true,
              data: null,
              builder: (context, data) => Text('$data'),
            ),
          ),
        );

        // Assert
        expect(find.byType(ElevatedButton), findsNothing);
        expect(find.text('Reintentar'), findsNothing);
      },
    );
  });
}
