/// Configuración de entorno — endpoints y flags.
///
/// Valores pasados en build time vía `--dart-define` (ej.
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/tekoapp-backend/api`), nunca
/// hardcodeados para producción. El default acá apunta al backend local para desarrollo directo
/// contra el emulador Android (`10.0.2.2` es el alias del host desde el emulador; en iOS
/// Simulator y dispositivos físicos en la misma red, usar la IP LAN de la máquina que corre el
/// backend — ver README para el detalle por plataforma).
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/tekoapp-backend/api',
  );

  /// Secret de Basic Auth de *cliente* (no de usuario) que exigen los endpoints pre-login
  /// (`/auth/nonce`, `/auth/login`, `/auth/public-key`, ver `BasicAuthGuard` del backend). Mobile
  /// no tiene servidor propio para ocultarlo (ver `.claude/rules/auth.md`, "Qué NO replicar del
  /// BFF de TekoApp-Web") — vive en el binario/config de la app, asumido extraíble con esfuerzo de
  /// reversing, igual que cualquier secret embebido en un cliente móvil.
  static const String basicAuthClientId = String.fromEnvironment(
    'BASIC_AUTH_CLIENT_ID',
  );
  static const String basicAuthClientSecret = String.fromEnvironment(
    'BASIC_AUTH_CLIENT_SECRET',
  );

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// Ambiente de negocio (`dev`/`qa`/`prod`) — determina qué releases de GitHub considera el
  /// chequeo de actualización (`core/update/`, ver openspec/specs/app-version-update.md). Distinto
  /// de `isProduction`: ese es el flag de compilación de Dart (release vs. debug), no el ambiente.
  static const String environment = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'dev',
  );

  /// Origen del backend sin el prefijo `/tekoapp-backend/api` — `socket_io_client` conecta contra
  /// el namespace (`/locations`) directamente sobre el origen, no sobre la ruta REST.
  static String get socketOrigin {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }
}
