import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/account_deletion/data/account_deletion_repository.dart';
import 'package:tekoapp_mobile/features/account_deletion/models/account_deletion_failure.dart';
import 'package:tekoapp_mobile/features/account_deletion/providers/account_deletion_repository_provider.dart';
import 'package:tekoapp_mobile/features/account_deletion/providers/cancel_deletion_controller_provider.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/models/scope_failure.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAccountDeletionRepository extends Mock
    implements AccountDeletionRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockAccountDeletionRepository accountDeletionRepository;
  late ProviderContainer container;

  setUp(() {
    authRepository = _MockAuthRepository();
    accountDeletionRepository = _MockAccountDeletionRepository();
    when(() => authRepository.readAccessToken()).thenAnswer((_) async => null);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        accountDeletionRepositoryProvider.overrideWithValue(
          accountDeletionRepository,
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'cancela la solicitud y refresca la sesión (el banner desaparece porque deletionScheduledAt vuelve a null)',
    () async {
      // Arrange
      when(
        () => accountDeletionRepository.cancelDeletion(),
      ).thenAnswer((_) async {});
      when(
        () => authRepository.fetchScope(),
      ).thenThrow(const ScopeUnavailableFailure());

      // Act
      await container.read(cancelDeletionControllerProvider.notifier).submit();

      // Assert
      verify(() => accountDeletionRepository.cancelDeletion()).called(1);
      expect(
        container.read(cancelDeletionControllerProvider).hasError,
        isFalse,
      );
    },
  );

  test(
    'deja el estado en AccountDeletionNotRequestedFailure si no había solicitud activa',
    () async {
      // Arrange
      when(() => accountDeletionRepository.cancelDeletion()).thenThrow(
        const AccountDeletionNotRequestedFailure(),
      );

      // Act
      await container.read(cancelDeletionControllerProvider.notifier).submit();

      // Assert
      final state = container.read(cancelDeletionControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<AccountDeletionNotRequestedFailure>());
      verifyNever(() => authRepository.fetchScope());
    },
  );
}
