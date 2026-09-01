import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_password_field.dart';

void main() {
  testWidgets('oculta la contraseña por default', (tester) async {
    // Arrange & Act
    final controller = TextEditingController(text: 'Sup3rSecreto!');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TekoPasswordField(
            labelText: 'Contraseña',
            controller: controller,
          ),
        ),
      ),
    );

    // Assert
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.obscureText, isTrue);
  });

  testWidgets('el botón de ojito revela y vuelve a ocultar la contraseña', (
    tester,
  ) async {
    // Arrange
    final controller = TextEditingController(text: 'Sup3rSecreto!');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TekoPasswordField(
            labelText: 'Contraseña',
            controller: controller,
          ),
        ),
      ),
    );

    // Act — primer tap revela
    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pump();

    // Assert
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    // Act — segundo tap vuelve a ocultar
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    // Assert
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
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
            child: TekoPasswordField(
              labelText: 'Contraseña',
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
}
