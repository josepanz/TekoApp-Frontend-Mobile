import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env.dart';

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
}

class SocketIoLocationsSocketService implements LocationsSocketService {
  io.Socket? _socket;

  @override
  void connect(String accessToken) {
    _socket?.dispose();
    _socket = io.io(
      '${Env.socketOrigin}/locations',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    )..connect();
  }

  @override
  void disconnect() {
    _socket?.dispose();
    _socket = null;
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
