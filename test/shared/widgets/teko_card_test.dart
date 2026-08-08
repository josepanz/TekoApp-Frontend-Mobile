import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_card.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('se renderiza en ${brightness.name} sin errores', (
      tester,
    ) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme:
              brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
          home: const Scaffold(body: TekoCard(child: Text('Contenido'))),
        ),
      );

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.text('Contenido'), findsOneWidget);
    });
  }
}
