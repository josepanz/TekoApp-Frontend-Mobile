import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:tekoapp_mobile/core/auth/rsa_encryptor.dart';

/// No valida contra la clave real del backend (eso lo hace José corriendo la app contra el
/// backend local, ver `openspec/decisions.md`) — valida que `RsaEncryptor` produce exactamente el
/// padding OAEP-SHA256 que el backend espera: cifra con un par de claves de prueba propio y
/// descifra con la misma librería/parámetros que usa `CryptoHelper.decrypt` (RSA-OAEP, SHA-256
/// para el hash principal y para MGF1), confirmando que el JSON `{password, nonce}` recuperado es
/// exactamente el original.
void main() {
  late RSAPublicKey publicKey;
  late RSAPrivateKey privateKey;

  setUpAll(() {
    final keyPair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    publicKey = keyPair.publicKey as RSAPublicKey;
    privateKey = keyPair.privateKey as RSAPrivateKey;
  });

  String decrypt(String base64Ciphertext) {
    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final decrypted = cipher.process(base64Decode(base64Ciphertext));
    return utf8.decode(decrypted);
  }

  test(
    'cifra {password, nonce} y el round-trip recupera exactamente el JSON original',
    () {
      // Arrange
      final encryptor = RsaEncryptor(
        CryptoUtils.encodeRSAPublicKeyToPem(publicKey),
      );

      // Act
      final ciphertext = encryptor.encryptLoginPayload(
        password: 'S3cr3t!Pass',
        nonce: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4',
      );
      final decrypted = decrypt(ciphertext);

      // Assert
      expect(
        jsonDecode(decrypted),
        equals({
          'password': 'S3cr3t!Pass',
          'nonce': 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4',
        }),
      );
    },
  );

  test('produce un cifrado distinto en cada llamada (seed OAEP aleatorio)', () {
    // Arrange
    final encryptor = RsaEncryptor(
      CryptoUtils.encodeRSAPublicKeyToPem(publicKey),
    );

    // Act
    final first = encryptor.encryptLoginPayload(
      password: 'pass',
      nonce: 'nonce-1',
    );
    final second = encryptor.encryptLoginPayload(
      password: 'pass',
      nonce: 'nonce-1',
    );

    // Assert
    expect(first, isNot(equals(second)));
  });
}
