import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/app.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';

/// `sessionProvider` real llama a `flutter_secure_storage` al construirse (ver
/// `core/auth/session_provider.dart`) — sin un mock de plataforma disponible en `flutter_test`,
/// eso dispara una excepción de plugin no manejada. Se fija un estado sincrónico acá, la
/// orquestación real de sesión tiene su propia suite (`test/core/auth/session_provider_test.dart`).
class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this._fixed);
  final SessionState _fixed;

  @override
  SessionState build() => _fixed;
}

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
            sessionProvider.overrideWith(
              () => _FixedSessionNotifier(const SessionUnauthenticated()),
            ),
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
