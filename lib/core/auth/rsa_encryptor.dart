import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/export.dart';

/// Cifra el payload de login `{password, nonce}` con la clave pública RSA del backend
/// (`GET /auth/public-key`) usando OAEP con SHA-256 — mismo digest para el hash principal y para
/// MGF1, el padding exacto que usa `CryptoHelper.decrypt(value, 'sha256')` del lado backend (ver
/// `openspec/decisions.md`, sección "Cifrado RSA del login").
class RsaEncryptor {
  RsaEncryptor(String publicKeyPem)
      : _publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);

  final RSAPublicKey _publicKey;

  /// Devuelve el payload cifrado en base64, listo para `LoginUserDTO.encryptedPassword`.
  String encryptLoginPayload({
    required String password,
    required String nonce,
  }) {
    final payloadJson = jsonEncode({'password': password, 'nonce': nonce});
    final input = Uint8List.fromList(utf8.encode(payloadJson));

    final cipher = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(_publicKey));

    return base64.encode(cipher.process(input));
  }
}
