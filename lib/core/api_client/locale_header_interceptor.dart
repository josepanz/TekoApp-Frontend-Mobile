import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../locale/locale_provider.dart';

const _supportedLanguageCodes = {'es', 'en'};

/// Manda `x-lang` con el idioma activo de la UI — mismo criterio que `LocaleController`
/// (preferencia explícita guardada o, si no hay, el idioma del sistema si es uno soportado,
/// español por default). El backend traduce sus mensajes de error/validación según este header
/// (`nestjs-i18n`, ver `.claude/rules/i18n.md`). Lee `SharedPreferences` directo (no vía Riverpod
/// `ref`) — mismo patrón que `BearerAuthInterceptor` con `flutter_secure_storage`, mantiene
/// `core/api_client` desacoplado del árbol de providers.
class LocaleHeaderInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!options.headers.containsKey('x-lang')) {
      final prefs = await SharedPreferences.getInstance();
      final explicit = prefs.getString(localePrefsKey);
      final systemCode = PlatformDispatcher.instance.locale.languageCode;
      options.headers['x-lang'] = explicit ??
          (_supportedLanguageCodes.contains(systemCode) ? systemCode : 'es');
    }
    handler.next(options);
  }
}
