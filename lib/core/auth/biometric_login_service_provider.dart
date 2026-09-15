import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_login_service.dart';

/// Instancia única del wrapper de `local_auth` — sin estado propio, así que un `Provider` simple
/// alcanza (no hace falta un `Notifier`, ver `.claude/rules/flutter-architecture.md`).
final biometricLoginServiceProvider = Provider<BiometricLoginService>((ref) {
  return BiometricLoginService();
});
