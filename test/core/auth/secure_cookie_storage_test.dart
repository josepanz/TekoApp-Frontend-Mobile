import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/secure_cookie_storage.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage secureStorage;
  late SecureCookieStorage storage;

  setUp(() {
    secureStorage = _MockSecureStorage();
    storage = SecureCookieStorage(secureStorage: secureStorage);
  });

  test('lee un valor delegando a flutter_secure_storage', () async {
    // Arrange
    when(
      () => secureStorage.read(key: 'cookie-key'),
    ).thenAnswer((_) async => 'cookie-value');

    // Act
    final result = await storage.read('cookie-key');

    // Assert
    expect(result, 'cookie-value');
  });

  test('devuelve null cuando la clave no existe', () async {
    // Arrange
    when(
      () => secureStorage.read(key: 'missing-key'),
    ).thenAnswer((_) async => null);

    // Act
    final result = await storage.read('missing-key');

    // Assert
    expect(result, isNull);
  });

  test('escribe un valor delegando a flutter_secure_storage', () async {
    // Arrange
    when(
      () => secureStorage.write(key: 'cookie-key', value: 'cookie-value'),
    ).thenAnswer((_) async {});

    // Act
    await storage.write('cookie-key', 'cookie-value');

    // Assert
    verify(
      () => secureStorage.write(key: 'cookie-key', value: 'cookie-value'),
    ).called(1);
  });

  test('elimina una clave delegando a flutter_secure_storage', () async {
    // Arrange
    when(
      () => secureStorage.delete(key: 'cookie-key'),
    ).thenAnswer((_) async {});

    // Act
    await storage.delete('cookie-key');

    // Assert
    verify(() => secureStorage.delete(key: 'cookie-key')).called(1);
  });

  test('elimina todas las claves indicadas una por una', () async {
    // Arrange
    when(() => secureStorage.delete(key: any(named: 'key'))).thenAnswer((
      _,
    ) async {});

    // Act
    await storage.deleteAll(['a', 'b', 'c']);

    // Assert
    verify(() => secureStorage.delete(key: 'a')).called(1);
    verify(() => secureStorage.delete(key: 'b')).called(1);
    verify(() => secureStorage.delete(key: 'c')).called(1);
  });
}
