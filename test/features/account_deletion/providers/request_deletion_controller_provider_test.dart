import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/account_deletion/data/account_deletion_repository.dart';
import 'package:tekoapp_mobile/features/account_deletion/models/account_deletion_failure.dart';
import 'package:tekoapp_mobile/features/account_deletion/models/deletion_blocker.dart';
import 'package:tekoapp_mobile/features/account_deletion/providers/account_deletion_repository_provider.dart';
import 'package:tekoapp_mobile/features/account_deletion/providers/request_deletion_controller_provider.dart';
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
    'pide el borrado y refresca la sesión cuando el backend lo acepta',
    () async {
      // Arrange
      when(
        () => accountDeletionRepository.requestDeletion(),
      ).thenAnswer((_) async {});
      when(
        () => authRepository.fetchScope(),
      ).thenThrow(const ScopeUnavailableFailure());

      // Act
      await container.read(requestDeletionControllerProvider.notifier).submit();

      // Assert
      verify(() => accountDeletionRepository.requestDeletion()).called(1);
      expect(
        container.read(requestDeletionControllerProvider).hasError,
        isFalse,
      );
    },
  );

  test(
    'deja el estado en AccountDeletionBlockedFailure con los bloqueantes cuando el backend los reporta',
    () async {
      // Arrange
      when(() => accountDeletionRepository.requestDeletion()).thenThrow(
        const AccountDeletionBlockedFailure([
          DeletionBlocker(type: DeletionBlockerType.pendingPayment, count: 1),
        ]),
      );

      // Act
      await container.read(requestDeletionControllerProvider.notifier).submit();

      // Assert
      final state = container.read(requestDeletionControllerProvider);
      expect(state.hasError, isTrue);
      final error = state.error as AccountDeletionBlockedFailure;
      expect(error.blockers, hasLength(1));
      expect(error.blockers.first.type, DeletionBlockerType.pendingPayment);
      // No debe refrescar la sesión si el pedido fue bloqueado.
      verifyNever(() => authRepository.fetchScope());
    },
  );
}
