import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tekoapp_mobile/app.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/features/auth/widgets/login_screen.dart';
import 'package:tekoapp_mobile/features/home/widgets/home_screen.dart';
import 'package:tekoapp_mobile/features/profile/widgets/profile_screen.dart';

/// `sessionProvider` real llama a `flutter_secure_storage` al construirse — sin mock de
/// plataforma en `flutter_test`, eso dispara una excepción de plugin no manejada (ver
/// `core/auth/session_provider.dart`). Se fija un estado sincrónico para no depender de eso; la
/// orquestación real de sesión tiene su propia suite (`test/core/auth/session_provider_test.dart`).
class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this._fixed);
  final SessionState _fixed;

  @override
  SessionState build() => _fixed;
}

/// El smoke test de red (`networkSmokeCheckProvider`) tiene su propia suite mockeando dio (ver
/// test/core/api_client/network_smoke_check_provider_test.dart) — acá se sobreescribe para que
/// estos tests de redirección no dependan de una red real.
List<Override> _overridesWithSession(SessionState session) => [
      networkSmokeCheckProvider.overrideWith((ref) async => const []),
      sessionProvider.overrideWith(() => _FixedSessionNotifier(session)),
    ];

void main() {
  testWidgets(
    'redirige a /login al navegar a una ruta protegida sin sesión',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overridesWithSession(const SessionUnauthenticated()),
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/perfil');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProfileScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );

  testWidgets(
    'no redirige al navegar a una ruta pública',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overridesWithSession(const SessionUnauthenticated()),
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));

      // Act
      router.go('/login');
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
