import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/models/login_failure.dart';
import 'package:tekoapp_mobile/features/auth/models/login_result.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/features/auth/providers/login_controller_provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    // `sessionProvider` también lee `readAccessToken()` al construirse (restauración inicial) —
    // se fija en "sin token" salvo que un test necesite otra cosa.
    when(() => repository.readAccessToken()).thenAnswer((_) async => null);
  });

  tearDown(() => container.dispose());

  test(
    'login exitoso deja el estado en éxito y autentica la sesión',
    () async {
      // Arrange
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const LoginResult(
          success: true,
          requiresNewPassword: false,
          accessToken: 'tok',
        ),
      );
      const user = UserSummary(
        referenceId: 'r1',
        email: 'a@b.com',
        firstName: 'A',
        lastName: 'B',
      );
      when(() => repository.fetchScope()).thenAnswer((_) async => user);

      // Act
      await container
          .read(loginControllerProvider.notifier)
          .submit(email: 'a@b.com', password: 'pass');

      // Assert
      expect(container.read(loginControllerProvider).hasError, isFalse);
      final session = container.read(sessionProvider);
      expect(session, isA<SessionAuthenticated>());
      expect((session as SessionAuthenticated).user, same(user));
    },
  );

  test(
    'propaga InvalidCredentialsFailure cuando el repositorio la lanza',
    () async {
      // Arrange
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const InvalidCredentialsFailure());

      // Act
      await container
          .read(loginControllerProvider.notifier)
          .submit(email: 'a@b.com', password: 'bad');

      // Assert
      final state = container.read(loginControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<InvalidCredentialsFailure>());
    },
  );

  test(
    'trata requiresNewPassword=true como credenciales inválidas (flujo aparte, no implementado)',
    () async {
      // Arrange
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async =>
            const LoginResult(success: false, requiresNewPassword: true),
      );

      // Act
      await container
          .read(loginControllerProvider.notifier)
          .submit(email: 'a@b.com', password: 'pass');

      // Assert
      expect(
        container.read(loginControllerProvider).error,
        isA<InvalidCredentialsFailure>(),
      );
      verifyNever(() => repository.fetchScope());
    },
  );
}
