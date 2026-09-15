import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/features/auth/providers/biometric_opt_in_controller_provider.dart';

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

  test('build() refleja si ya hay credenciales guardadas', () async {
    // Arrange
    when(
      () => repository.hasBiometricCredentials(),
    ).thenAnswer((_) async => true);

    // Act
    final result =
        await container.read(biometricOptInControllerProvider.future);

    // Assert
    expect(result, isTrue);
  });

  test('enable() guarda las credenciales y deja el estado en true', () async {
    // Arrange
    when(
      () => repository.hasBiometricCredentials(),
    ).thenAnswer((_) async => false);
    when(
      () => repository.saveBiometricCredentials(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    await container.read(biometricOptInControllerProvider.future);

    // Act
    await container
        .read(biometricOptInControllerProvider.notifier)
        .enable(email: 'a@b.com', password: 'pass');

    // Assert
    expect(container.read(biometricOptInControllerProvider).value, isTrue);
    verify(
      () => repository.saveBiometricCredentials(
        email: 'a@b.com',
        password: 'pass',
      ),
    ).called(1);
  });

  test('disable() borra las credenciales y deja el estado en false', () async {
    // Arrange
    when(
      () => repository.hasBiometricCredentials(),
    ).thenAnswer((_) async => true);
    when(
      () => repository.clearBiometricCredentials(),
    ).thenAnswer((_) async {});
    await container.read(biometricOptInControllerProvider.future);

    // Act
    await container.read(biometricOptInControllerProvider.notifier).disable();

    // Assert
    expect(container.read(biometricOptInControllerProvider).value, isFalse);
    verify(() => repository.clearBiometricCredentials()).called(1);
  });
}
