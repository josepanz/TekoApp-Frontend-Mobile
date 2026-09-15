import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env.dart';

/// Estado de conexión observable del socket de ubicación (ver M-03) — para que la UI pueda
/// mostrar "reconectando…" o un error en vez de dejar la ubicación muerta en silencio.
enum LocationsSocketConnectionState {
  connected,
  reconnecting,
  disconnected,
  error
}

/// Ubicación de un profesional recibida por el socket de `/locations` — payload de
/// `locationUpdated`, ver `LocationsGateway` en el backend.
class ProfessionalLocationUpdate {
  const ProfessionalLocationUpdate({
    required this.professionalId,
    required this.latitude,
    required this.longitude,
  });

  factory ProfessionalLocationUpdate.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;
    return ProfessionalLocationUpdate(
      professionalId: json['professionalId'] as int,
      latitude: (location['latitude'] as num).toDouble(),
      longitude: (location['longitude'] as num).toDouble(),
    );
  }

  final int professionalId;
  final double latitude;
  final double longitude;
}

/// Contrato del socket de `/locations` — interfaz propia (no exponer `socket_io_client` directo
/// fuera de `core/`) para que los tests inyecten un fake en vez de tocar red real, ver
/// `.claude/rules/test.md`.
abstract class LocationsSocketService {
  void connect(String accessToken);
  void disconnect();
  void emitUpdateLocation({
    required double latitude,
    required double longitude,
  });
  void onLocationUpdated(void Function(ProfessionalLocationUpdate) listener);

  /// `connected` tras un `connect()`/reconexión exitosa; `reconnecting` mientras el socket
  /// intenta recuperarse solo de una caída; `error` si agotó los reintentos (ver M-03);
  /// `disconnected` tras un `disconnect()` explícito.
  Stream<LocationsSocketConnectionState> get connectionState;
}

class SocketIoLocationsSocketService implements LocationsSocketService {
  SocketIoLocationsSocketService({
    Future<String?> Function()? tokenReader,
    this.maxConsecutiveFailures = 3,
  }) : _tokenReader = tokenReader;

  final Future<String?> Function()? _tokenReader;

  /// Tope de fallos consecutivos de conexión antes de rendirse y pasar a `error` — sin esto,
  /// el socket (o un JWT vencido que nunca se puede renovar) reintentaría para siempre en
  /// silencio. Ver M-03.
  final int maxConsecutiveFailures;

  io.Socket? _socket;
  final _connectionStateController =
      StreamController<LocationsSocketConnectionState>.broadcast();
  bool _intentionalDisconnect = false;
  int _consecutiveFailures = 0;

  @override
  Stream<LocationsSocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  void connect(String accessToken) {
    // Instancia única compartida por toda la app (ver `locationsSocketServiceProvider`) — más de
    // un feature puede querer "estar conectado" a la vez (un profesional emitiendo + el mismo
    // usuario mirando el mapa de cercanos en modo cliente); no tirar abajo una conexión ya viva
    // solo porque otro feature también llamó `connect()`.
    if (_socket?.connected ?? false) return;
    _socket?.dispose();

    _intentionalDisconnect = false;
    _consecutiveFailures = 0;

    final socket = io.io(
      '${Env.socketOrigin}/locations',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuthFn(
            (callback) =>
                _resolveAuth(fallbackToken: accessToken, callback: callback),
          )
          .setReconnectionAttempts(maxConsecutiveFailures)
          .disableAutoConnect()
          .build(),
    );
    wireSocketForTesting(socket);
    socket.connect();
  }

  /// Registra los listeners de estado sobre [socket] y lo adopta como el socket activo — parte
  /// de `connect()`, extraído para que los tests puedan ejercitar la máquina de estados con un
  /// `io.Socket` real pero nunca conectado a red (ver `locations_socket_service_test.dart`).
  @visibleForTesting
  void wireSocketForTesting(io.Socket socket) {
    _intentionalDisconnect = false;
    _consecutiveFailures = 0;
    _socket = socket;

    socket.on('connect', (_) {
      _consecutiveFailures = 0;
      _connectionStateController.add(LocationsSocketConnectionState.connected);
    });
    socket.on('connect_error', (_) => _onConnectionFailure());
    socket.on('disconnect', (_) {
      if (_intentionalDisconnect) return;
      _onConnectionFailure();
    });
  }

  /// Expone [_resolveAuth] para tests — el resto de la clase no necesita llamarlo directo.
  @visibleForTesting
  void resolveAuthForTesting({
    required String fallbackToken,
    required void Function(Map<String, dynamic> auth) callback,
  }) =>
      _resolveAuth(fallbackToken: fallbackToken, callback: callback);

  /// El socket.io-client subyacente ya reintenta solo (con backoff propio) mientras
  /// `reconnection` esté habilitado (default) — acá solo reflejamos ese proceso en
  /// [connectionState] y le ponemos un tope duro, porque la librería por default reintenta
  /// infinito y un JWT vencido que nunca se puede renovar nunca daría `reconnect_failed`.
  void _onConnectionFailure() {
    if (_intentionalDisconnect) return;
    _consecutiveFailures++;
    if (_consecutiveFailures >= maxConsecutiveFailures) {
      _connectionStateController.add(LocationsSocketConnectionState.error);
      disconnect();
      return;
    }
    _connectionStateController.add(LocationsSocketConnectionState.reconnecting);
  }

  /// Se llama en cada intento de conexión (inicial y cada reconexión automática) — con
  /// [_tokenReader] configurado, pide un token fresco en vez de reusar uno que puede haber
  /// vencido a mitad de sesión.
  void _resolveAuth({
    required String fallbackToken,
    required void Function(Map<String, dynamic> auth) callback,
  }) {
    final reader = _tokenReader;
    if (reader == null) {
      callback({'token': fallbackToken});
      return;
    }
    unawaited(
      reader().then((token) {
        if (token == null) {
          // Sin token no hay con qué reconectar — cortamos en vez de seguir reintentando.
          _connectionStateController.add(LocationsSocketConnectionState.error);
          disconnect();
          return;
        }
        callback({'token': token});
      }),
    );
  }

  @override
  void disconnect() {
    _intentionalDisconnect = true;
    _socket?.dispose();
    _socket = null;
    _connectionStateController.add(LocationsSocketConnectionState.disconnected);
  }

  @override
  void emitUpdateLocation({
    required double latitude,
    required double longitude,
  }) {
    _socket?.emit('updateLocation', {
      'location': {'latitude': latitude, 'longitude': longitude},
    });
  }

  @override
  void onLocationUpdated(void Function(ProfessionalLocationUpdate) listener) {
    _socket?.on('locationUpdated', (data) {
      listener(
        ProfessionalLocationUpdate.fromJson(
          Map<String, dynamic>.from(data as Map),
        ),
      );
    });
  }
}
