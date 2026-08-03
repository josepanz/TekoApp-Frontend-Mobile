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

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
}
