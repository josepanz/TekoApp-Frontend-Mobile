import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/app.dart';

void main() {
  testWidgets(
    'la app arranca y muestra la pantalla de inicio sin errores',
    (tester) async {
      // Arrange
      await tester.pumpWidget(const ProviderScope(child: TekoApp()));

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    },
  );
}
