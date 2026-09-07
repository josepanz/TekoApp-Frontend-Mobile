import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/access_token_reader_provider.dart';
import '../../../core/realtime/locations_socket_service.dart';

/// Instancia única durante la vida de la app — un profesional online mantiene una sola conexión de
/// socket, no una por pantalla. Los tests overridean este provider con un fake, ver
/// `.claude/rules/test.md`.
///
/// `tokenReader` (ver M-03) deja que el servicio pida un token fresco en cada reconexión
/// automática, en vez de reintentar para siempre con el que ya venció.
final locationsSocketServiceProvider = Provider<LocationsSocketService>((ref) {
  final service = SocketIoLocationsSocketService(
    tokenReader: ref.read(accessTokenReaderProvider),
  );
  ref.onDispose(service.disconnect);
  return service;
});

/// Estado de conexión del socket compartido (ver M-03 y `LocationsSocketService.connectionState`)
/// — expuesto para que las pantallas que miran tracking en vivo puedan avisar "se perdió la
/// conexión, reintentando…" en vez de dejar la ubicación muerta en silencio.
final locationsSocketConnectionStateProvider =
    StreamProvider<LocationsSocketConnectionState>((ref) {
  return ref.watch(locationsSocketServiceProvider).connectionState;
});
