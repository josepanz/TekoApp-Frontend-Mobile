import 'package:basic_utils/basic_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/models/login_failure.dart';

class _MockDio extends Mock implements Dio {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockDio dio;
  late _MockSecureStorage secureStorage;
  late AuthRepository repository;
  late String testPublicKeyPem;

  setUpAll(() {
    registerFallbackValue(Options());
    final keyPair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    testPublicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(
      keyPair.publicKey as RSAPublicKey,
    );
  });

  setUp(() {
    dio = _MockDio();
    secureStorage = _MockSecureStorage();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = AuthRepository(
      ApiClient(dio: dio),
      secureStorage: secureStorage,
    );
  });

  Response<Map<String, dynamic>> jsonResponse(
    String path,
    Map<String, dynamic> data,
  ) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  group('fetchPublicKeyPem', () {
    test('devuelve la clave pública del backend', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>(
          '/auth/public-key',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse('/auth/public-key', {
          'publicKeyPem': testPublicKeyPem,
        }),
      );

      // Act
      final result = await repository.fetchPublicKeyPem();

      // Assert
      expect(result, testPublicKeyPem);
    });
  });

  group('fetchNonce', () {
    test('devuelve el nonce del backend', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/nonce',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse('/auth/nonce', {'nonce': 'nonce-abc'}),
      );

      // Act
      final result = await repository.fetchNonce();

      // Assert
      expect(result, 'nonce-abc');
    });
  });

  group('login', () {
    void mockPreLoginCalls() {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/auth/public-key',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse('/auth/public-key', {
          'publicKeyPem': testPublicKeyPem,
        }),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/nonce',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse('/auth/nonce', {'nonce': 'nonce-abc'}),
      );
    }

    test(
      'persiste el accessToken y retorna éxito cuando las credenciales son válidas',
      () async {
        // Arrange
        mockPreLoginCalls();
        when(
          () => dio.post<Map<String, dynamic>>(
            '/auth/login',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => jsonResponse('/auth/login', {
            'login': true,
            'requiredNewPassword': false,
            'accessToken': 'access-token-123',
          }),
        );
        when(
          () => secureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        // Act
        final result = await repository.login(
          email: 'user@test.com',
          password: 'S3cr3t!',
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.requiresNewPassword, isFalse);
        expect(result.accessToken, 'access-token-123');
        verify(
          () => secureStorage.write(
            key: AuthRepository.accessTokenStorageKey,
            value: 'access-token-123',
          ),
        ).called(1);
      },
    );

    test(
      'lanza InvalidCredentialsFailure cuando el backend responde 401',
      () async {
        // Arrange
        mockPreLoginCalls();
        when(
          () => dio.post<Map<String, dynamic>>(
            '/auth/login',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 401,
            ),
          ),
        );

        // Act & Assert
        await expectLater(
          repository.login(email: 'user@test.com', password: 'bad-pass'),
          throwsA(isA<InvalidCredentialsFailure>()),
        );
      },
    );

    test(
      'lanza ServiceUnavailableFailure cuando el backend responde 5xx',
      () async {
        // Arrange
        mockPreLoginCalls();
        when(
          () => dio.post<Map<String, dynamic>>(
            '/auth/login',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 503,
            ),
          ),
        );

        // Act & Assert
        await expectLater(
          repository.login(email: 'user@test.com', password: 'pass'),
          throwsA(isA<ServiceUnavailableFailure>()),
        );
      },
    );

    test(
      'lanza NoConnectionFailure cuando no hay respuesta del servidor',
      () async {
        // Arrange
        mockPreLoginCalls();
        when(
          () => dio.post<Map<String, dynamic>>(
            '/auth/login',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            type: DioExceptionType.connectionError,
          ),
        );

        // Act & Assert
        await expectLater(
          repository.login(email: 'user@test.com', password: 'pass'),
          throwsA(isA<NoConnectionFailure>()),
        );
      },
    );
  });
}
