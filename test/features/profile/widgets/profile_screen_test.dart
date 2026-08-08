import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/app.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/features/auth/widgets/login_screen.dart';
import 'package:tekoapp_mobile/features/home/widgets/home_screen.dart';
import 'package:tekoapp_mobile/features/profile/widgets/profile_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Ver `test/app_redirect_test.dart` — mismo motivo para fijar `sessionProvider` en vez de dejar
/// que resuelva solo.
class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this._fixed);
  final SessionState _fixed;

  @override
  SessionState build() => _fixed;
}

void main() {
  testWidgets(
    'el botón de logout limpia la sesión y navega a /login',
    (tester) async {
      // Arrange
      final repository = _MockAuthRepository();
      when(() => repository.clearSession()).thenAnswer((_) async {});
      const user = UserSummary(
        referenceId: 'ref-1',
        email: 'a@b.com',
        firstName: 'Ana',
        lastName: 'Pérez',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            networkSmokeCheckProvider.overrideWith((ref) async => const []),
            authRepositoryProvider.overrideWithValue(repository),
            sessionProvider.overrideWith(
              () => _FixedSessionNotifier(const SessionAuthenticated(user)),
            ),
          ],
          child: const TekoApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
      router.go('/perfil');
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Act — se busca por tipo, no por texto, para no depender del locale resuelto en el test
      // (el binding de flutter_test resuelve `en` por default, ver test/features/auth/widgets/
      // login_screen_test.dart para el mismo problema con un locale forzado en su lugar).
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.clearSession()).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
    },
  );
}
