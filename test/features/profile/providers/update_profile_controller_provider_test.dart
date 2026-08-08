import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/models/scope_failure.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/features/profile/data/profile_repository.dart';
import 'package:tekoapp_mobile/features/profile/models/profile_failure.dart';
import 'package:tekoapp_mobile/features/profile/providers/profile_repository_provider.dart';
import 'package:tekoapp_mobile/features/profile/providers/update_profile_controller_provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockProfileRepository profileRepository;
  late ProviderContainer container;

  setUp(() {
    authRepository = _MockAuthRepository();
    profileRepository = _MockProfileRepository();
    when(() => authRepository.readAccessToken()).thenAnswer((_) async => null);
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'llama a updateMe con los datos del formulario y refresca la sesión',
    () async {
      // Arrange
      when(
        () => profileRepository.updateMe(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenAnswer((_) async {});
      // `refreshAfterLogin()` llama a `fetchScope()` sobre `authRepositoryProvider` (no sobre
      // `ProfileRepository`) — se simula un backend momentáneamente caído para confirmar que eso
      // NO hace fallar el `submit` (SessionNotifier ya maneja ScopeUnavailableFailure sin
      // relanzar, ver test/core/auth/session_provider_test.dart).
      when(
        () => authRepository.fetchScope(),
      ).thenThrow(const ScopeUnavailableFailure());

      // Act
      await container.read(updateProfileControllerProvider.notifier).submit(
            firstName: 'Ana',
            lastName: 'Pérez',
            phoneNumber: '+595981234567',
          );

      // Assert
      verify(
        () => profileRepository.updateMe(
          firstName: 'Ana',
          lastName: 'Pérez',
          phoneNumber: '+595981234567',
        ),
      ).called(1);
      expect(container.read(updateProfileControllerProvider).hasError, isFalse);
    },
  );

  test(
    'deja el estado en error cuando el backend rechaza los datos',
    () async {
      // Arrange
      when(
        () => profileRepository.updateMe(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phoneNumber: any(named: 'phoneNumber'),
        ),
      ).thenThrow(const ProfileValidationFailure());

      // Act
      await container
          .read(updateProfileControllerProvider.notifier)
          .submit(firstName: 'Ana', lastName: 'Pérez', phoneNumber: '123');

      // Assert
      final state = container.read(updateProfileControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<ProfileValidationFailure>());
    },
  );
}
