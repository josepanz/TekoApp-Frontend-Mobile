import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tekoapp_mobile/app.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';
import 'package:tekoapp_mobile/features/auth/widgets/login_screen.dart';
import 'package:tekoapp_mobile/features/home/widgets/home_screen.dart';
import 'package:tekoapp_mobile/features/profile/widgets/profile_screen.dart';

/// El smoke test de red (`networkSmokeCheckProvider`) tiene su propia suite mockeando dio (ver
/// test/core/api_client/network_smoke_check_provider_test.dart) — acá se sobreescribe para que
/// estos tests de redirección no dependan de una red real.
List<Override> get _noNetworkOverrides => [
      networkSmokeCheckProvider.overrideWith((ref) async => const []),
    ];

void main() {
  testWidgets(
    'redirige a /login al navegar a una ruta protegida sin sesión',
    (tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(overrides: _noNetworkOverrides, child: const TekoApp()),
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
        ProviderScope(overrides: _noNetworkOverrides, child: const TekoApp()),
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
