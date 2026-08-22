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

  test('emite la última ubicación conocida del profesional', () async {
    // Arrange
    when(
      () => repository.fetchProfessionalLocation(2),
    ).thenAnswer((_) async => _knownLocation);

    // Act
    final first = await container.read(
      assignedProfessionalLocationProvider(2).future,
    );

    // Assert
    expect(first?.latitude, -25.29);
    expect(first?.longitude, -57.62);
  });

  test(
    'emite null cuando el profesional todavía no compartió ubicación',
    () async {
      // Arrange
      when(
        () => repository.fetchProfessionalLocation(2),
      ).thenThrow(const LocationsValidationFailure());

      // Act
      final first = await container.read(
        assignedProfessionalLocationProvider(2).future,
      );

      // Assert
      expect(first, isNull);
    },
  );

  test(
    'se actualiza con el evento en vivo del profesional asignado',
    () async {
      // Arrange
      when(
        () => repository.fetchProfessionalLocation(2),
      ).thenAnswer((_) async => _knownLocation);
      keepAlive();
      await container.read(assignedProfessionalLocationProvider(2).future);
      // Deja correr el resto del generador (conectar el socket + registrar el listener) antes de
      // emitir — `.future` solo espera el primer valor, no el resto de la configuración en vuelo.
      await Future<void>.delayed(Duration.zero);

      // Act
      socket.emit(
        const ProfessionalLocationUpdate(
          professionalId: 2,
          latitude: -25.1,
          longitude: -57.1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final updated =
          container.read(assignedProfessionalLocationProvider(2)).value;

      // Assert
      expect(updated?.latitude, -25.1);
      expect(updated?.longitude, -57.1);
    },
  );

  test(
    'ignora eventos en vivo de otro profesional distinto al asignado',
    () async {
      // Arrange
      when(
        () => repository.fetchProfessionalLocation(2),
      ).thenAnswer((_) async => _knownLocation);
      keepAlive();
      await container.read(assignedProfessionalLocationProvider(2).future);
      await Future<void>.delayed(Duration.zero);

      // Act
      socket.emit(
        const ProfessionalLocationUpdate(
          professionalId: 999,
          latitude: -1,
          longitude: -1,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final state =
          container.read(assignedProfessionalLocationProvider(2)).value;

      // Assert
      expect(state?.latitude, -25.29);
    },
  );
}
