import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compartido con `core/api_client/locale_header_interceptor.dart` (manda el mismo valor como
/// header `x-lang` al backend) — un solo lugar con el nombre de la clave para no desincronizar.
const localePrefsKey = 'app_locale';

/// Selector de idioma explícito (ver `openspec/changes/0006-i18n-and-polish.md`) — `null` significa
/// "seguir el idioma del sistema operativo" (comportamiento por defecto hasta esta fase).
class LocaleController extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(localePrefsKey);
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(localePrefsKey);
    } else {
      await prefs.setString(localePrefsKey, locale.languageCode);
    }
    state = AsyncData(locale);
  }
}

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale?>(LocaleController.new);
