import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/fcm_token_storage_provider.dart';
import 'package:tekoapp_mobile/features/notifications/data/notifications_repository.dart';
import 'package:tekoapp_mobile/features/notifications/models/device_type.dart';
import 'package:tekoapp_mobile/features/notifications/providers/notifications_repository_provider.dart';
import 'package:tekoapp_mobile/features/notifications/providers/push_messaging_provider.dart';
import 'package:tekoapp_mobile/features/notifications/providers/push_registration_controller.dart';

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DeviceType.android);
  });

  late _MockNotificationsRepository repository;
  late bool permissionGranted;
  late String? tokenToReturn;
  late String? writtenReferenceId;
  late String? storedReferenceId;
  late bool cleared;
  late ProviderContainer container;

  setUp(() {
    repository = _MockNotificationsRepository();
    permissionGranted = true;
    tokenToReturn = 'a-fcm-token';
    writtenReferenceId = null;
    storedReferenceId = 'stored-ref-1';
    cleared = false;

    container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
        notificationPermissionRequesterProvider.overrideWithValue(
          () async => permissionGranted,
        ),
        fcmTokenReaderProvider.overrideWithValue(() async => tokenToReturn),
        currentDeviceTypeProvider.overrideWithValue(DeviceType.android),
        fcmTokenReferenceWriterProvider.overrideWithValue((referenceId) async {
          writtenReferenceId = referenceId;
        }),
        fcmTokenReferenceReaderProvider.overrideWithValue(
          () async => storedReferenceId,
        ),
        fcmTokenReferenceClearerProvider.overrideWithValue(() async {
          cleared = true;
        }),
      ],
    );
    addTearDown(container.dispose);
  });

  group('registerIfPermitted', () {
    test('registra el token y persiste el referenceId devuelto', () async {
      // Arrange
      when(
        () => repository.registerFcmToken(
          token: 'a-fcm-token',
          deviceType: DeviceType.android,
        ),
      ).thenAnswer((_) async => 'new-ref-1');

      // Act
      await container
          .read(pushRegistrationControllerProvider.notifier)
          .registerIfPermitted();

      // Assert
      expect(writtenReferenceId, 'new-ref-1');
    });

    test('no registra nada si el permiso fue denegado', () async {
      // Arrange
      permissionGranted = false;
      container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          notificationPermissionRequesterProvider.overrideWithValue(
            () async => false,
          ),
          fcmTokenReaderProvider.overrideWithValue(() async => tokenToReturn),
          currentDeviceTypeProvider.overrideWithValue(DeviceType.android),
        ],
      );

      // Act
      await container
          .read(pushRegistrationControllerProvider.notifier)
          .registerIfPermitted();

      // Assert
      verifyNever(
        () => repository.registerFcmToken(
          token: any(named: 'token'),
          deviceType: any(named: 'deviceType'),
        ),
      );
    });
  });

  group('unregister', () {
    test('da de baja el token guardado y limpia el storage', () async {
      // Arrange
      when(() => repository.removeFcmToken('stored-ref-1')).thenAnswer(
        (_) async {},
      );

      // Act
      await container
          .read(pushRegistrationControllerProvider.notifier)
          .unregister();

      // Assert
      verify(() => repository.removeFcmToken('stored-ref-1')).called(1);
      expect(cleared, true);
    });

    test('no intenta dar de baja si no hay token guardado', () async {
      // Arrange
      storedReferenceId = null;
      container = ProviderContainer(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(repository),
          fcmTokenReferenceReaderProvider.overrideWithValue(
            () async => null,
          ),
        ],
      );

      // Act
      await container
          .read(pushRegistrationControllerProvider.notifier)
          .unregister();

      // Assert
      verifyNever(() => repository.removeFcmToken(any()));
    });
  });
}
