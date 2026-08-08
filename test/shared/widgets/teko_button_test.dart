import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_button.dart';

Widget wrap(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('se renderiza en ${brightness.name} sin errores', (
      tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        wrap(
          const TekoButton(label: 'Ingresar', onPressed: null),
          brightness: brightness,
        ),
      );

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.text('Ingresar'), findsOneWidget);
    });
  }

  testWidgets('dispara onPressed al tocarlo', (tester) async {
    // Arrange
    var tapped = false;
    await tester.pumpWidget(
      wrap(TekoButton(label: 'Guardar', onPressed: () => tapped = true)),
    );

    // Act
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    // Assert
    expect(tapped, isTrue);
  });

  testWidgets('se deshabilita cuando onPressed es null', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      wrap(const TekoButton(label: 'Deshabilitado', onPressed: null)),
    );

    // Assert
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('muestra un spinner y se deshabilita cuando loading=true', (
    tester,
  ) async {
    // Arrange & Act
    await tester.pumpWidget(
      wrap(TekoButton(label: 'Cargando', onPressed: () {}, loading: true)),
    );

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('todas las variantes se renderizan sin errores', (
    tester,
  ) async {
    for (final variant in TekoButtonVariant.values) {
      // Arrange & Act
      await tester.pumpWidget(
        wrap(
          TekoButton(label: variant.name, onPressed: () {}, variant: variant),
        ),
      );

      // Assert
      expect(tester.takeException(), isNull);
    }
  });
}
