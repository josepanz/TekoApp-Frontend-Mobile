import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/biometric_login_service.dart';
import 'package:tekoapp_mobile/core/auth/biometric_login_service_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/models/login_failure.dart';
import 'package:tekoapp_mobile/features/auth/models/login_result.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/features/auth/providers/biometric_login_controller_provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockBiometricLoginService extends Mock
    implements BiometricLoginService {}

void main() {
  late _MockAuthRepository repository;
  late _MockBiometricLoginService biometricService;
  late ProviderContainer container;

  setUp(() {
    repository = _MockAuthRepository();
    biometricService = _MockBiometricLoginService();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        biometricLoginServiceProvider.overrideWithValue(biometricService),
      ],
    );
    // `sessionProvider` lee `readAccessToken()` al construirse (restauración inicial).
    when(() => repository.readAccessToken()).thenAnswer((_) async => null);
  });

  tearDown(() => container.dispose());

  test(
    'si el usuario cancela el prompt biométrico, el estado nunca pasa por loading',
    () async {
      // Arrange
      when(
        () => biometricService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => false);

      // Act
      await container
          .read(biometricLoginControllerProvider.notifier)
          .submit(localizedReason: 'reason');

      // Assert
      final state = container.read(biometricLoginControllerProvider);
      expect(state.hasError, isFalse);
      verifyNever(() => repository.readBiometricCredentials());
    },
  );

  test(
    'con biometría aprobada, repite el login normal con las credenciales guardadas',
    () async {
      // Arrange
      when(
        () => biometricService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);
      when(() => repository.readBiometricCredentials()).thenAnswer(
        (_) async => (email: 'a@b.com', password: 'pass'),
      );
      when(
        () => repository.login(email: 'a@b.com', password: 'pass'),
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
          .read(biometricLoginControllerProvider.notifier)
          .submit(localizedReason: 'reason');

      // Assert
      final state = container.read(biometricLoginControllerProvider);
      expect(state.hasError, isFalse);
      final session = container.read(sessionProvider);
      expect(session, isA<SessionAuthenticated>());
    },
  );

  test(
    'sin credenciales guardadas, falla defensivamente sin intentar el login',
    () async {
      // Arrange
      when(
        () => biometricService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => repository.readBiometricCredentials(),
      ).thenAnswer((_) async => null);

      // Act
      await container
          .read(biometricLoginControllerProvider.notifier)
          .submit(localizedReason: 'reason');

      // Assert
      final state = container.read(biometricLoginControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<InvalidCredentialsFailure>());
      verifyNever(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  test(
    'credenciales guardadas vencidas propagan InvalidCredentialsFailure',
    () async {
      // Arrange
      when(
        () => biometricService.authenticate(
          localizedReason: any(named: 'localizedReason'),
        ),
      ).thenAnswer((_) async => true);
      when(() => repository.readBiometricCredentials()).thenAnswer(
        (_) async => (email: 'a@b.com', password: 'old'),
      );
      when(
        () => repository.login(email: 'a@b.com', password: 'old'),
      ).thenAnswer(
        (_) async =>
            const LoginResult(success: false, requiresNewPassword: false),
      );

      // Act
      await container
          .read(biometricLoginControllerProvider.notifier)
          .submit(localizedReason: 'reason');

      // Assert
      final state = container.read(biometricLoginControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<InvalidCredentialsFailure>());
    },
  );
}
