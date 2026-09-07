import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekoapp_mobile/app.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/core/api_client/network_smoke_check_provider.dart';
import 'package:tekoapp_mobile/features/auth/widgets/login_screen.dart';
import 'package:tekoapp_mobile/features/home/widgets/home_screen.dart';
import 'package:tekoapp_mobile/features/notifications/providers/push_messaging_provider.dart';
import 'package:tekoapp_mobile/features/notifications/providers/push_registration_controller.dart';
import 'package:tekoapp_mobile/features/profile/widgets/profile_screen.dart';

class _MockDio extends Mock implements Dio {}

/// `PushNotificationGateway` (montado por `TekoApp`) llama a `firebase_messaging` real en
/// `initState` — sin proyecto Firebase inicializado en `flutter test` y sin un mock de plataforma
/// disponible para ese plugin (a diferencia de `flutter_secure_storage`/`shared_preferences`, que
/// sí se mockean acá), se overridean estos providers en vez del plugin.
class _NoopPushRegistrationController extends PushRegistrationController {
  @override
  Future<void> registerIfPermitted() async {}

  @override
  Future<void> unregister() async {}
}

final _pushMessagingTestOverrides = <Override>[
  onForegroundMessageProvider.overrideWithValue(() => const Stream.empty()),
  onMessageOpenedAppProvider.overrideWithValue(() => const Stream.empty()),
  initialPushMessageReaderProvider.overrideWithValue(() async => null),
  pushRegistrationControllerProvider.overrideWith(
    () => _NoopPushRegistrationController(),
  ),
];

/// Único flujo e2e de esta fase (login + un flujo representativo, ver `.claude/rules/test.md`):
/// login real → home → Mi perfil (ruta protegida) → logout → el guard de `go_router` redirige
/// solo. Solo se mockea el límite de red (`Dio`, vía `apiClientProvider`) — todo lo demás
/// (`AuthRepository`, `SessionNotifier`, `LoginController`, el cifrado RSA real, el guard con
/// `refreshListenable`) es el código real de la app, ejercitado de punta a punta.
///
/// Corre como test de widgets (`flutter test`), no como `integration_test/` — este entorno no
/// tiene un emulador/dispositivo disponible para correr `integration_test` de verdad (requiere
/// `flutter test integration_test/` contra un device real, ver `openspec/decisions.md`). Esto
/// sigue siendo un flujo end-to-end real de la app (nada de `sessionProvider` fijado a mano, a
/// diferencia de `test/app_redirect_test.dart`/`test/features/profile/widgets/profile_screen_test.dart`),
/// solo que corre en el binding de test en vez de en un device.
///
/// `flutter_secure_storage` no tiene implementación de plataforma bajo `flutter test` — se
/// mockea su `MethodChannel` con un mapa en memoria para que `AuthRepository`/`SecureCookieStorage`
/// (código real, sin overrides) funcionen igual.
void main() {
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureStorage = <String, String>{};

  setUp(() {
    // `LocaleController` (selector de idioma) usa `SharedPreferences` — mismo criterio que el
    // mock en memoria de `flutter_secure_storage` de acá abajo, ver `core/locale/locale_provider.dart`.
    // `push_permission_prompted: true` evita que `PushNotificationGateway` abra su diálogo de
    // permiso al detectar el login real de este test — no es lo que este flujo e2e verifica.
    SharedPreferences.setMockInitialValues({'push_permission_prompted': true});
    secureStorage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>();
      switch (call.method) {
        case 'read':
          return secureStorage[args!['key']];
        case 'write':
          secureStorage[args!['key'] as String] = args['value'] as String;
          return null;
        case 'delete':
          secureStorage.remove(args!['key']);
          return null;
        case 'deleteAll':
          secureStorage.clear();
          return null;
        case 'containsKey':
          return secureStorage.containsKey(args!['key']);
        case 'readAll':
          return secureStorage;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets('login -> home -> Mi perfil -> logout de punta a punta', (
    tester,
  ) async {
    // Arrange — par de claves de prueba (nunca la clave real del backend, ver
    // test/core/auth/rsa_encryptor_test.dart) para poder descifrar lo que el login realmente
    // cifra y confirmar que el payload es el correcto.
    final keyPair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(
      keyPair.publicKey as RSAPublicKey,
    );
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    String decryptPayload(String base64Ciphertext) {
      final cipher = OAEPEncoding.withSHA256(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
      return utf8.decode(cipher.process(base64Decode(base64Ciphertext)));
    }

    final dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    when(
      () => dio.get<Map<String, dynamic>>(
        '/auth/public-key',
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/public-key'),
        data: {'publicKeyPem': publicKeyPem},
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/nonce',
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/nonce'),
        data: {'nonce': 'test-nonce'},
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) async {
      final body = invocation.namedArguments[const Symbol('data')]
          as Map<String, dynamic>;
      final decrypted =
          jsonDecode(decryptPayload(body['encryptedPassword'] as String))
              as Map<String, dynamic>;
      expect(decrypted['password'], 'S3cr3t!');
      expect(decrypted['nonce'], 'test-nonce');

      return Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        data: {
          'login': true,
          'requiredNewPassword': false,
          'accessToken': 'fake-access-token',
        },
      );
    });
    when(() => dio.get<Map<String, dynamic>>('/auth/scope')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/auth/scope'),
        data: {
          'user': {
            'id': 'ref-1',
            'email': 'user@test.com',
            'firstName': 'Ana',
            'lastName': 'Pérez',
          },
          'roles': <Map<String, dynamic>>[],
          'permissions': <Map<String, dynamic>>[],
        },
      ),
    );

    // Act — arrancar la app sin sesión guardada.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
          networkSmokeCheckProvider.overrideWith((ref) async => const []),
          ..._pushMessagingTestOverrides,
        ],
        child: const TekoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Assert — sin sesión, `/` (protegida) ya redirigió a /login al arrancar.
    final router = GoRouter.of(tester.element(find.byType(LoginScreen)));
    router.go('/perfil');
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // Act — completar y enviar el login.
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'user@test.com');
    await tester.enterText(textFields.at(1), 'S3cr3t!');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    // Assert — login exitoso navega a home.
    expect(find.byType(HomeScreen), findsOneWidget);

    // Act — ahora autenticado, /perfil ya no redirige.
    router.go('/perfil');
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(ProfileScreen), findsOneWidget);

    // Act — logout (el selector de idioma agregado en la Fase 0006 empuja el botón fuera del
    // viewport fijo de test, hay que scrollearlo a la vista antes de tocarlo).
    await tester.ensureVisible(find.byKey(const Key('profile_logout_button')));
    await tester.tap(find.byKey(const Key('profile_logout_button')));
    await tester.pumpAndSettle();

    // Assert — el guard de go_router (refreshListenable) redirige solo, sin navegación manual.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
