import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/auth/session_state.dart';
import 'profile_repository_provider.dart';

/// Un valor por usuario logueado — varios usuarios pueden compartir el mismo dispositivo.
String _prefsKeyFor(String userReferenceId) =>
    'share_contact_info:$userReferenceId';

/// Checkbox "Tarea 8" (`openspec/decisions.md`, backend): si el usuario logueado comparte su
/// email/teléfono con quien vea un servicio suyo (`Users.shareContactInfo`, `PUT /auth/me`).
///
/// El backend NO expone el valor actual en ninguna lectura: ni `GET /auth/scope`
/// (`UserScopeResponseDTO.user` no lo declara) ni `GET /auth/me` (`AuthApiService.me()` arma la
/// respuesta solo con lo que trae el JWT, que nunca incluyó este campo) — únicamente la respuesta
/// de `PUT /auth/me` lo devuelve fresco, justo después de guardarlo. Sin una fuente de verdad
/// legible del lado del servidor, este provider recuerda el último valor guardado EN ESTE
/// DISPOSITIVO (mismo criterio que `BiometricOptInController`, que enfrenta la misma clase de
/// problema) — default `true` (mismo default que la columna en la base) cuando el dispositivo
/// nunca guardó nada para este usuario.
class ShareContactInfoController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final session = ref.watch(sessionProvider);
    if (session is! SessionAuthenticated) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKeyFor(session.user.referenceId)) ?? true;
  }

  Future<void> setSharesContactInfo(bool value) async {
    final session = ref.read(sessionProvider);
    if (session is! SessionAuthenticated) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(profileRepositoryProvider)
          .updateMe(shareContactInfo: value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyFor(session.user.referenceId), value);
      return value;
    });
  }
}

final shareContactInfoControllerProvider =
    AsyncNotifierProvider<ShareContactInfoController, bool>(
  ShareContactInfoController.new,
);
