// Suite: ubicación del profesional asignado (exactLocationUpdated, suscripción a la sala, fallback)
// Casos: CP-MOB-LOC-001..005 (ver test/qa/casos/CP-LOC.md)
// Tipo: unitaria (provider)   Prioridad: P1
// Precondiciones: socket y repositorio falsos, ProviderContainer con overrides
// Trazabilidad: M8 tracking en vivo
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/access_token_reader_provider.dart';
import 'package:tekoapp_mobile/core/realtime/locations_socket_service.dart';
import 'package:tekoapp_mobile/features/locations/data/locations_repository.dart';
import 'package:tekoapp_mobile/features/locations/models/locations_failure.dart';
import 'package:tekoapp_mobile/features/locations/models/professional_last_location.dart';
import 'package:tekoapp_mobile/features/locations/providers/assigned_professional_location_provider.dart';
import 'package:tekoapp_mobile/features/locations/providers/locations_repository_provider.dart';
import 'package:tekoapp_mobile/features/locations/providers/locations_socket_provider.dart';

class _MockLocationsRepository extends Mock implements LocationsRepository {}

class _FakeLocationsSocketService implements LocationsSocketService {
  void Function(ProfessionalLocationUpdate)? _listener;
  final exactController =
      StreamController<ProfessionalLocationUpdate>.broadcast();
  final errorController =
      StreamController<LocationsSubscriptionError>.broadcast();
  final subscribed = <int>[];
  final unsubscribed = <int>[];

  @override
  Stream<LocationsSocketConnectionState> get connectionState =>
      const Stream.empty();

  @override
  Stream<ProfessionalLocationUpdate> get exactLocationUpdates =>
      exactController.stream;

  @override
  Stream<LocationsSubscriptionError> get subscriptionErrors =>
      errorController.stream;

  @override
  void subscribeToProfessional(int professionalId) =>
      subscribed.add(professionalId);

  @override
  void unsubscribeFromProfessional(int professionalId) =>
      unsubscribed.add(professionalId);

  @override
  void connect(String accessToken) {}

  @override
  void disconnect() {}

  @override
  void emitUpdateLocation({
    required double latitude,
    required double longitude,
  }) {}

  @override
  void onLocationUpdated(void Function(ProfessionalLocationUpdate) listener) {
    _listener = listener;
  }

  /// Canal global (aproximado).
  void emit(ProfessionalLocationUpdate update) => _listener?.call(update);
}

const _knownLocation = ProfessionalLastLocation(
  latitude: -25.29,
  longitude: -57.62,
);

void main() {
  late _MockLocationsRepository repository;
  late _FakeLocationsSocketService socket;
  late ProviderContainer container;

  setUp(() {
    repository = _MockLocationsRepository();
    socket = _FakeLocationsSocketService();
    container = ProviderContainer(
      overrides: [
        locationsRepositoryProvider.overrideWithValue(repository),
        locationsSocketServiceProvider.overrideWithValue(socket),
        accessTokenReaderProvider.overrideWithValue(
          () async => 'a-real-token',
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  // `autoDispose`: mantenerlo vivo durante el test, igual que `ref.watch` lo haría desde
  // `_AssignedProfessionalTrackingSection` en la app real — se llama DESPUÉS de armar el stub de
  // cada test (si no, dispara el fetch inicial contra un mock todavía sin `when()`).
  void keepAlive() =>
      container.listen(assignedProfessionalLocationProvider(2), (_, __) {});

  void stubLocation(int id) => when(
        () => repository.fetchProfessionalLocation(id),
      ).thenAnswer((_) async => _knownLocation);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('emite la última ubicación conocida del profesional', () async {
    stubLocation(2);

    final first = await container.read(
      assignedProfessionalLocationProvider(2).future,
    );

    expect(first?.latitude, -25.29);
    expect(first?.longitude, -57.62);
  });

  test(
    'emite null cuando el profesional todavía no compartió ubicación',
    () async {
      when(
        () => repository.fetchProfessionalLocation(2),
      ).thenThrow(const LocationsValidationFailure());

      final first = await container.read(
        assignedProfessionalLocationProvider(2).future,
      );

      expect(first, isNull);
    },
  );

  test('se actualiza con exactLocationUpdated del profesional asignado',
      () async {
    stubLocation(2);
    keepAlive();
    await container.read(assignedProfessionalLocationProvider(2).future);
    // `.future` solo espera el primer valor, no el resto de la configuración en vuelo.
    await settle();

    socket.exactController.add(
      const ProfessionalLocationUpdate(
        professionalId: 2,
        latitude: -25.1,
        longitude: -57.1,
      ),
    );
    await settle();
    final updated =
        container.read(assignedProfessionalLocationProvider(2)).value;

    expect(updated?.latitude, -25.1);
    expect(updated?.longitude, -57.1);
  });

  test('ignora eventos exactos de otro profesional', () async {
    stubLocation(2);
    keepAlive();
    await container.read(assignedProfessionalLocationProvider(2).future);
    await settle();

    socket.exactController.add(
      const ProfessionalLocationUpdate(
        professionalId: 999,
        latitude: -1,
        longitude: -1,
      ),
    );
    await settle();

    expect(
      container.read(assignedProfessionalLocationProvider(2)).value?.latitude,
      -25.29,
    );
  });

  group('suscripción a la sala del profesional', () {
    test('se suscribe al montar con el id interno del profesional', () async {
      stubLocation(2);
      keepAlive();
      await container.read(assignedProfessionalLocationProvider(2).future);
      await settle();

      expect(socket.subscribed, [2]);
      expect(socket.unsubscribed, isEmpty);
    });

    test('se desuscribe al dispose', () async {
      stubLocation(2);
      final subscription = container.listen(
        assignedProfessionalLocationProvider(2),
        (_, __) {},
      );
      await container.read(assignedProfessionalLocationProvider(2).future);
      await settle();

      subscription.close();
      await settle();

      expect(socket.unsubscribed, [2]);
    });

    test('al cambiar de profesional se cierra el anterior y abre el nuevo',
        () async {
      stubLocation(2);
      stubLocation(3);
      final first = container.listen(
        assignedProfessionalLocationProvider(2),
        (_, __) {},
      );
      await container.read(assignedProfessionalLocationProvider(2).future);
      await settle();

      first.close();
      container.listen(assignedProfessionalLocationProvider(3), (_, __) {});
      await container.read(assignedProfessionalLocationProvider(3).future);
      await settle();

      expect(socket.unsubscribed, [2]);
      expect(socket.subscribed, [2, 3]);
    });

    test('ante subscriptionError cae a la posición aproximada', () async {
      stubLocation(2);
      keepAlive();
      await container.read(assignedProfessionalLocationProvider(2).future);
      await settle();
      const approx = ProfessionalLocationUpdate(
        professionalId: 2,
        latitude: -25.5,
        longitude: -57.5,
      );

      // Sin error la aproximada se ignora: la exacta es la fuente de verdad.
      socket.emit(approx);
      await settle();
      expect(
        container.read(assignedProfessionalLocationProvider(2)).value?.latitude,
        -25.29,
      );

      socket.errorController.add(
        const LocationsSubscriptionError(professionalId: 2, message: 'no'),
      );
      await settle();
      socket.emit(approx);
      await settle();

      final state = container.read(assignedProfessionalLocationProvider(2));
      expect(state.hasError, isFalse);
      expect(state.value?.latitude, -25.5);
    });

    test('un subscriptionError de otro profesional no activa el fallback',
        () async {
      stubLocation(2);
      keepAlive();
      await container.read(assignedProfessionalLocationProvider(2).future);
      await settle();

      socket.errorController.add(
        const LocationsSubscriptionError(professionalId: 9, message: 'no'),
      );
      await settle();
      socket.emit(
        const ProfessionalLocationUpdate(
          professionalId: 2,
          latitude: -1,
          longitude: -1,
        ),
      );
      await settle();

      expect(
        container.read(assignedProfessionalLocationProvider(2)).value?.latitude,
        -25.29,
      );
    });
  });
}
