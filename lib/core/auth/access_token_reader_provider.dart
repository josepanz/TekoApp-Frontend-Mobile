import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage_keys.dart';

/// Lee el `accessToken` persistido — detrás de un provider de función (mismo patrón que
/// `currentPositionFetcherProvider`) para que los tests lo overrideen en vez de tocar el
/// `MethodChannel` real de `flutter_secure_storage`.
final accessTokenReaderProvider = Provider<Future<String?> Function()>((ref) {
  const storage = FlutterSecureStorage();
  return () => storage.read(key: TokenStorageKeys.accessToken);
});
