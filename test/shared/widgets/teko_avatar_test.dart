import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_avatar.dart';

/// No cubre el caso con `avatarUrl` real (requeriría mockear `Image.network`, no vale la pena la
/// complejidad para un wrapper delgado sobre un widget de Flutter ya probado) — sí cubre el
/// fallback a iniciales, que es la lógica propia de este widget.
void main() {
  testWidgets('muestra las iniciales de nombre y apellido sin avatarUrl', (
    tester,
  ) async {
    // Arrange & Act
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TekoAvatar(name: 'Ana Pérez')),
      ),
    );

    // Assert
    expect(find.text('AP'), findsOneWidget);
  });

  testWidgets('muestra una sola inicial para un nombre de una palabra', (
    tester,
  ) async {
    // Arrange & Act
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TekoAvatar(name: 'Ana')),
      ),
    );

    // Assert
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('expone un label accesible con el nombre', (tester) async {
    // Arrange — el árbol de semántica no se construye en tests sin un handle activo.
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: TekoAvatar(name: 'Ana Pérez')),
      ),
    );

    // Act & Assert
    expect(find.bySemanticsLabel('Avatar de Ana Pérez'), findsOneWidget);
    handle.dispose();
  });
}
