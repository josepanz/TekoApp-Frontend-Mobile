import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/locations_socket_service.dart';

/// Instancia única durante la vida de la app — un profesional online mantiene una sola conexión de
/// socket, no una por pantalla. Los tests overridean este provider con un fake, ver
/// `.claude/rules/test.md`.
final locationsSocketServiceProvider = Provider<LocationsSocketService>((ref) {
  final service = SocketIoLocationsSocketService();
  ref.onDispose(service.disconnect);
  return service;
});
