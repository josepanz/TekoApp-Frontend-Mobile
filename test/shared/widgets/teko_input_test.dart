import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_input.dart';

void main() {
  testWidgets('muestra el label — nunca un input sin nombre accesible', (
    tester,
  ) async {
    // Arrange & Act
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TekoInput(label: 'Teléfono')),
      ),
    );

    // Assert
    expect(find.text('Teléfono'), findsOneWidget);
  });

  testWidgets('muestra el error de validación asociado al campo', (
    tester,
  ) async {
    // Arrange
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TekoInput(
              label: 'Teléfono',
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Requerido' : null,
            ),
          ),
        ),
      ),
    );

    // Act
    formKey.currentState!.validate();
    await tester.pump();

    // Assert
    expect(find.text('Requerido'), findsOneWidget);
  });

  testWidgets('respeta el valor inicial cuando no hay controller', (
    tester,
  ) async {
    // Arrange & Act
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: TekoInput(label: 'Nombre', initialValue: 'Ana'),
        ),
      ),
    );

    // Assert
    expect(find.text('Ana'), findsOneWidget);
  });
}
