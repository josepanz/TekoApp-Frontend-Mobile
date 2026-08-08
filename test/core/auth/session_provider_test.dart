import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/models/scope_failure.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test(
    'arranca en SessionUnknown y pasa a Unauthenticated si no hay token guardado',
    () async {
      // Arrange
      when(() => repository.readAccessToken()).thenAnswer((_) async => null);

      // Act
      final initial = container.read(sessionProvider);
      await pumpEventQueue();
      final resolved = container.read(sessionProvider);

      // Assert
      expect(initial, isA<SessionUnknown>());
      expect(resolved, isA<SessionUnauthenticated>());
    },
  );

  test(
    'resuelve a Authenticated cuando hay token y GET /auth/scope responde bien',
    () async {
      // Arrange
      when(
        () => repository.readAccessToken(),
      ).thenAnswer((_) async => 'token-123');
      const user = UserSummary(
        referenceId: 'ref-1',
        email: 'a@b.com',
        firstName: 'Ana',
        lastName: 'Pérez',
      );
      when(() => repository.fetchScope()).thenAnswer((_) async => user);

      // Act
      container.read(sessionProvider);
      await pumpEventQueue();
      final resolved = container.read(sessionProvider);

      // Assert
      expect(resolved, isA<SessionAuthenticated>());
      expect((resolved as SessionAuthenticated).user, same(user));
    },
  );

  test(
    'cierra sesión localmente cuando GET /auth/scope falla con sesión vencida (401 tras refresh)',
    () async {
      // Arrange
      when(
        () => repository.readAccessToken(),
      ).thenAnswer((_) async => 'token-vencido');
      when(() => repository.fetchScope())
          .thenThrow(const SessionExpiredFailure());
      when(() => repository.clearSession()).thenAnswer((_) async {});

      // Act
      container.read(sessionProvider);
      await pumpEventQueue();
      final resolved = container.read(sessionProvider);

      // Assert
      expect(resolved, isA<SessionUnauthenticated>());
      verify(() => repository.clearSession()).called(1);
    },
  );

  test(
    'nunca cierra sesión ante 5xx/sin conexión - estado ServiceUnavailable distinto',
    () async {
      // Arrange
      when(
        () => repository.readAccessToken(),
      ).thenAnswer((_) async => 'token-123');
      when(
        () => repository.fetchScope(),
      ).thenThrow(const ScopeUnavailableFailure());

      // Act
      container.read(sessionProvider);
      await pumpEventQueue();
      final resolved = container.read(sessionProvider);

      // Assert
      expect(resolved, isA<SessionServiceUnavailable>());
      verifyNever(() => repository.clearSession());
    },
  );

  test('logout limpia la sesión local y pasa a Unauthenticated', () async {
    // Arrange
    when(() => repository.readAccessToken()).thenAnswer((_) async => null);
    when(() => repository.clearSession()).thenAnswer((_) async {});
    container.read(sessionProvider);
    await pumpEventQueue();

    // Act
    await container.read(sessionProvider.notifier).logout();

    // Assert
    expect(container.read(sessionProvider), isA<SessionUnauthenticated>());
    verify(() => repository.clearSession()).called(1);
  });
}
