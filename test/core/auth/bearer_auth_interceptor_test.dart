import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/bearer_auth_interceptor.dart';
import 'package:tekoapp_mobile/core/auth/token_storage_keys.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockHandler extends Mock implements RequestInterceptorHandler {}

void main() {
  late _MockSecureStorage secureStorage;
  late BearerAuthInterceptor interceptor;
  late _MockHandler handler;

  setUp(() {
    secureStorage = _MockSecureStorage();
    interceptor = BearerAuthInterceptor(secureStorage: secureStorage);
    handler = _MockHandler();
  });

  test(
    'adjunta el Bearer token cuando hay uno guardado y la request no trae Authorization propio',
    () async {
      // Arrange
      when(
        () => secureStorage.read(key: TokenStorageKeys.accessToken),
      ).thenAnswer((_) async => 'token-123');
      final options = RequestOptions(path: '/auth/scope');

      // Act
      interceptor.onRequest(options, handler);
      await pumpEventQueue();

      // Assert
      expect(options.headers['Authorization'], 'Bearer token-123');
      verify(() => handler.next(options)).called(1);
    },
  );

  test('no adjunta nada cuando no hay token guardado', () async {
    // Arrange
    when(
      () => secureStorage.read(key: TokenStorageKeys.accessToken),
    ).thenAnswer((_) async => null);
    final options = RequestOptions(path: '/countries');

    // Act
    interceptor.onRequest(options, handler);
    await pumpEventQueue();

    // Assert
    expect(options.headers.containsKey('Authorization'), isFalse);
    verify(() => handler.next(options)).called(1);
  });

  test('no pisa un Authorization ya seteado (Basic Auth de cliente)', () async {
    // Arrange
    final options = RequestOptions(
      path: '/auth/nonce',
      headers: {'Authorization': 'Basic xyz'},
    );

    // Act
    interceptor.onRequest(options, handler);
    await pumpEventQueue();

    // Assert
    expect(options.headers['Authorization'], 'Basic xyz');
    verifyNever(() => secureStorage.read(key: any(named: 'key')));
    verify(() => handler.next(options)).called(1);
  });
}
