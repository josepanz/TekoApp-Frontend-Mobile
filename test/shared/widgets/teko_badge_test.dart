import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_badge.dart';

void main() {
  testWidgets('siempre muestra texto, nunca solo un color', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: TekoBadge(label: 'Activo', variant: TekoBadgeVariant.success),
        ),
      ),
    );

    // Assert
    expect(find.text('Activo'), findsOneWidget);
  });

  testWidgets('todas las variantes se renderizan en ambos temas sin errores', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      for (final variant in TekoBadgeVariant.values) {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme:
                brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
            home: Scaffold(
              body: TekoBadge(label: variant.name, variant: variant),
            ),
          ),
        );

        // Assert
        expect(tester.takeException(), isNull);
      }
    }
  });
}
