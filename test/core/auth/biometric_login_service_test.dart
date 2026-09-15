import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/biometric_login_service.dart';

class _MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late _MockLocalAuthentication localAuth;
  late BiometricLoginService service;

  setUp(() {
    localAuth = _MockLocalAuthentication();
    service = BiometricLoginService(localAuth: localAuth);
  });

  group('canAuthenticate', () {
    test('true cuando el dispositivo soporta biometría y tiene una enrolada',
        () async {
      // Arrange
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);

      // Act & Assert
      expect(await service.canAuthenticate(), isTrue);
    });

    test('false si el dispositivo no soporta autenticación local', () async {
      // Arrange
      when(
        () => localAuth.isDeviceSupported(),
      ).thenAnswer((_) async => false);

      // Act & Assert
      expect(await service.canAuthenticate(), isFalse);
      verifyNever(() => localAuth.canCheckBiometrics);
    });

    test('false si soporta el dispositivo pero no hay biometría enrolada',
        () async {
      // Arrange
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => false);

      // Act & Assert
      expect(await service.canAuthenticate(), isFalse);
    });

    test('false (nunca lanza) si el canal nativo no está disponible', () async {
      // Arrange — mismo caso que un emulador/entorno de test sin plugin nativo registrado.
      when(
        () => localAuth.isDeviceSupported(),
      ).thenThrow(Exception('MissingPluginException'));

      // Act & Assert
      expect(await service.canAuthenticate(), isFalse);
    });
  });

  group('authenticate', () {
    test('true cuando el usuario aprueba el prompt', () async {
      // Arrange
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: true,
        ),
      ).thenAnswer((_) async => true);

      // Act & Assert
      expect(
        await service.authenticate(localizedReason: 'confirmá tu identidad'),
        isTrue,
      );
    });

    test('false cuando el usuario cancela el prompt', () async {
      // Arrange
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: true,
        ),
      ).thenAnswer((_) async => false);

      // Act & Assert
      expect(
        await service.authenticate(localizedReason: 'confirmá tu identidad'),
        isFalse,
      );
    });

    test('false (nunca lanza) si local_auth lanza LocalAuthException',
        () async {
      // Arrange
      when(
        () => localAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          biometricOnly: true,
        ),
      ).thenThrow(
        const LocalAuthException(
          code: LocalAuthExceptionCode.noBiometricsEnrolled,
          description: 'sin huella',
        ),
      );

      // Act & Assert
      expect(
        await service.authenticate(localizedReason: 'confirmá tu identidad'),
        isFalse,
      );
    });
  });
}
