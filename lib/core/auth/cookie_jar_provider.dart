import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'secure_cookie_storage.dart';

/// El `refreshToken` viaja SOLO como cookie httpOnly, nunca en el body (ver
/// `openspec/decisions.md`) — este jar es lo que permite que `dio` participe en ese intercambio de
/// cookies, persistido de forma segura entre reinicios de la app vía `SecureCookieStorage`.
final cookieJarProvider = Provider<PersistCookieJar>((ref) {
  return PersistCookieJar(storage: SecureCookieStorage());
});
