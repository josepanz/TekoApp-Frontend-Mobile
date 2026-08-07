import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/app.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';

void main() {
  testWidgets(
    'la app arranca y muestra la pantalla de inicio sin errores',
    (tester) async {
      // Arrange — el smoke test de red tiene su propia suite mockeando dio (ver
      // test/core/api_client/network_smoke_check_provider_test.dart); acá se sobreescribe para no
      // depender de una red real ni acoplar este test de arranque a ese detalle.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkSmokeCheckProvider.overrideWith((ref) async => const []),
          ],
          child: const TekoApp(),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
    },
  );
}
