import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Adapter de `Storage` (interfaz de `cookie_jar`) que persiste las cookies a través de
/// `flutter_secure_storage` en vez del archivo plano que usa el `Storage` default de `cookie_jar`
/// — el `refreshToken` viaja únicamente como cookie httpOnly (ver `openspec/decisions.md`), así
/// que sin este adapter quedaría en texto plano en disco entre reinicios de la app.
class SecureCookieStorage implements Storage {
  SecureCookieStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _secureStorage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _secureStorage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _secureStorage.delete(key: key);

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _secureStorage.delete(key: key);
    }
  }
}
