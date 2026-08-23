import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage_keys.dart';

/// Persistencia del `referenceId` del token FCM ya registrado — mismo patrón que
/// `accessTokenReaderProvider` (provider de función, para que los tests lo overrideen sin tocar
/// el `MethodChannel` real de `flutter_secure_storage`).
final fcmTokenReferenceReaderProvider = Provider<Future<String?> Function()>((
  ref,
) {
  const storage = FlutterSecureStorage();
  return () => storage.read(key: TokenStorageKeys.fcmTokenReferenceId);
});

final fcmTokenReferenceWriterProvider =
    Provider<Future<void> Function(String)>((ref) {
  const storage = FlutterSecureStorage();
  return (referenceId) => storage.write(
        key: TokenStorageKeys.fcmTokenReferenceId,
        value: referenceId,
      );
});

final fcmTokenReferenceClearerProvider = Provider<Future<void> Function()>((
  ref,
) {
  const storage = FlutterSecureStorage();
  return () => storage.delete(key: TokenStorageKeys.fcmTokenReferenceId);
});
