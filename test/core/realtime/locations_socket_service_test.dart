import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:tekoapp_mobile/core/realtime/locations_socket_service.dart';

/// Construye un `io.Socket` real pero nunca conectado a red — `disableAutoConnect()` evita que
/// el `Manager` intente abrir nada al construirlo, y como los tests nunca llaman a `.connect()`
/// sobre él, tampoco lo hace después. Los eventos se simulan a mano con `.emit(...)`, que solo
/// invoca los listeners registrados (sin tocar sockets/DNS reales).
io.Socket buildDisconnectedSocket() => io.io(
      'http://127.0.0.1:0/locations',
      io.OptionBuilder().disableAutoConnect().build(),
    );

void main() {
  group('ProfessionalLocationUpdate.fromJson', () {
    test('parsea el payload de locationUpdated del backend', () {
      // Arrange
      final json = {
        'professionalId': 42,
        'location': {
          'latitude': -25.2637,
          'longitude': -57.5759,
          'timestamp': '2026-08-09T00:00:00.000Z',
        },
      };

      // Act
      final update = ProfessionalLocationUpdate.fromJson(json);

      // Assert
      expect(update.professionalId, 42);
      expect(update.latitude, -25.2637);
      expect(update.longitude, -57.5759);
    });
  });

  group('SocketIoLocationsSocketService — estado de conexión (M-03)', () {
    late SocketIoLocationsSocketService service;
    late io.Socket socket;

    setUp(() {
      service = SocketIoLocationsSocketService(maxConsecutiveFailures: 3);
      socket = buildDisconnectedSocket();
    });

    test('un disconnect dispara un intento de reconexión', () async {
      // Arrange
      service.wireSocketForTesting(socket);
      final states = <LocationsSocketConnectionState>[];
      final subscription = service.connectionState.listen(states.add);

      // Act — el socket ya estaba conectado y se cae por un blip de red.
      socket.emit('disconnect', 'transport close');
      await pumpEventQueue();

      // Assert
      expect(states, [LocationsSocketConnectionState.reconnecting]);
      await subscription.cancel();
    });

    test(
      'agotados los reintentos (maxConsecutiveFailures), el estado queda en error',
      () async {
        // Arrange
        service.wireSocketForTesting(socket);
        final states = <LocationsSocketConnectionState>[];
        final subscription = service.connectionState.listen(states.add);

        // Act — 3 fallos consecutivos de conexión, ninguno interrumpido por un connect exitoso.
        socket.emit('connect_error', 'timeout');
        socket.emit('connect_error', 'timeout');
        socket.emit('connect_error', 'timeout');
        await pumpEventQueue();

        // Assert — al 3er fallo se rinde: pasa a error y corta la conexión (M-03: "no
        // reintentes infinito").
        expect(states, [
          LocationsSocketConnectionState.reconnecting,
          LocationsSocketConnectionState.reconnecting,
          LocationsSocketConnectionState.error,
          LocationsSocketConnectionState.disconnected,
        ]);
        await subscription.cancel();
      },
    );

    test(
      'un connect exitoso entre medio resetea el conteo de fallos',
      () async {
        // Arrange
        service.wireSocketForTesting(socket);
        final states = <LocationsSocketConnectionState>[];
        final subscription = service.connectionState.listen(states.add);

        // Act
        socket.emit('connect_error', 'timeout');
        socket.emit('connect_error', 'timeout');
        socket.emit('connect');
        socket.emit('connect_error', 'timeout');
        socket.emit('connect_error', 'timeout');
        await pumpEventQueue();

        // Assert — nunca llegó a acumular 3 fallos SEGUIDOS, no debería haber error.
        expect(states, isNot(contains(LocationsSocketConnectionState.error)));
        await subscription.cancel();
      },
    );

    test(
      'un disconnect después de llamar disconnect() no dispara reconexión',
      () async {
        // Arrange
        service.wireSocketForTesting(socket);
        final states = <LocationsSocketConnectionState>[];
        final subscription = service.connectionState.listen(states.add);

        // Act
        service.disconnect();
        await pumpEventQueue();

        // Assert
        expect(states, [LocationsSocketConnectionState.disconnected]);
        await subscription.cancel();
      },
    );

    test(
      'con tokenReader configurado, cada auth pide un token fresco',
      () async {
        // Arrange
        var callCount = 0;
        service = SocketIoLocationsSocketService(
          tokenReader: () async {
            callCount++;
            return 'fresh-token-$callCount';
          },
        );
        Map<String, dynamic>? received;

        // Act
        service.resolveAuthForTesting(
          fallbackToken: 'stale-token',
          callback: (auth) => received = auth,
        );
        await pumpEventQueue();

        // Assert
        expect(callCount, 1);
        expect(received, {'token': 'fresh-token-1'});
      },
    );

    test(
      'sin tokenReader, la auth usa el token con el que se llamó a connect()',
      () async {
        // Arrange
        Map<String, dynamic>? received;

        // Act
        service.resolveAuthForTesting(
          fallbackToken: 'stale-token',
          callback: (auth) => received = auth,
        );
        await pumpEventQueue();

        // Assert
        expect(received, {'token': 'stale-token'});
      },
    );

    test(
      'si el tokenReader no devuelve token, corta y pasa a error en vez de reintentar',
      () async {
        // Arrange
        service = SocketIoLocationsSocketService(tokenReader: () async => null);
        service.wireSocketForTesting(socket);
        final states = <LocationsSocketConnectionState>[];
        final subscription = service.connectionState.listen(states.add);
        var callbackInvoked = false;

        // Act
        service.resolveAuthForTesting(
          fallbackToken: 'stale-token',
          callback: (_) => callbackInvoked = true,
        );
        await pumpEventQueue();

        // Assert
        expect(callbackInvoked, isFalse);
        expect(states, [
          LocationsSocketConnectionState.error,
          LocationsSocketConnectionState.disconnected,
        ]);
        await subscription.cancel();
      },
    );
  });
}
