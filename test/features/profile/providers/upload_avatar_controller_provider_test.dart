import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/models/scope_failure.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/features/profile/data/profile_repository.dart';
import 'package:tekoapp_mobile/features/profile/models/profile_failure.dart';
import 'package:tekoapp_mobile/features/profile/providers/profile_repository_provider.dart';
import 'package:tekoapp_mobile/features/profile/providers/upload_avatar_controller_provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockProfileRepository profileRepository;
  late ProviderContainer container;
  late Uint8List bytes;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    authRepository = _MockAuthRepository();
    profileRepository = _MockProfileRepository();
    bytes = Uint8List.fromList([1, 2, 3]);
    when(() => authRepository.readAccessToken()).thenAnswer((_) async => null);
    when(
      () => authRepository.fetchScope(),
    ).thenThrow(const ScopeUnavailableFailure());
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'sube el archivo, persiste la key y refresca la sesión en ese orden',
    () async {
      // Arrange
      when(
        () => profileRepository.uploadAvatar(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          mimeType: any(named: 'mimeType'),
        ),
      ).thenAnswer((_) async => 'key-abc.jpg');
      when(
        () => profileRepository.updateMe(avatarKey: any(named: 'avatarKey')),
      ).thenAnswer((_) async {});

      // Act
      await container
          .read(uploadAvatarControllerProvider.notifier)
          .submit(bytes: bytes, filename: 'foto.jpg', mimeType: 'image/jpeg');

      // Assert
      verifyInOrder([
        () => profileRepository.uploadAvatar(
              bytes: bytes,
              filename: 'foto.jpg',
              mimeType: 'image/jpeg',
            ),
        () => profileRepository.updateMe(avatarKey: 'key-abc.jpg'),
      ]);
    },
  );

  test(
    'deja el estado en error y nunca llama a updateMe si la subida falla',
    () async {
      // Arrange
      when(
        () => profileRepository.uploadAvatar(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          mimeType: any(named: 'mimeType'),
        ),
      ).thenThrow(const AvatarTooLargeFailure());

      // Act
      await container
          .read(uploadAvatarControllerProvider.notifier)
          .submit(bytes: bytes, filename: 'foto.jpg', mimeType: 'image/jpeg');

      // Assert
      final state = container.read(uploadAvatarControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<AvatarTooLargeFailure>());
      verifyNever(
        () => profileRepository.updateMe(avatarKey: any(named: 'avatarKey')),
      );
    },
  );
}
