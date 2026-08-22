import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/access_token_reader_provider.dart';
import 'package:tekoapp_mobile/core/location/current_location_provider.dart';
import 'package:tekoapp_mobile/core/realtime/locations_socket_service.dart';
import 'package:tekoapp_mobile/features/locations/data/locations_repository.dart';
import 'package:tekoapp_mobile/features/locations/models/nearby_professional.dart';
import 'package:tekoapp_mobile/features/locations/providers/locations_repository_provider.dart';
import 'package:tekoapp_mobile/features/locations/providers/locations_socket_provider.dart';
import 'package:tekoapp_mobile/features/locations/providers/nearby_professionals_provider.dart';

class _MockLocationsRepository extends Mock implements LocationsRepository {}

class _FakeLocationsSocketService implements LocationsSocketService {
  void Function(ProfessionalLocationUpdate)? _listener;
  bool connected = false;

  @override
  void connect(String accessToken) => connected = true;

  @override
  void disconnect() => connected = false;

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

const _professional = NearbyProfessional(
  id: 1,
  referenceId: 'prof-ref-1',
  categoryId: 3,
  description: 'Plomero',
  hourlyRate: 50000,
  latitude: -25.29,
  longitude: -57.62,
  distanceKm: 1.2,
  isOnline: true,
  averageRating: 4.5,
);

void main() {
  late _MockLocationsRepository repository;
  late _FakeLocationsSocketService socket;
  late ProviderContainer container;

  setUp(() {
    repository = _MockLocationsRepository();
    socket = _FakeLocationsSocketService();
    when(
      () => repository.fetchNearby(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => [_professional]);

    container = ProviderContainer(
      overrides: [
        locationsRepositoryProvider.overrideWithValue(repository),
        locationsSocketServiceProvider.overrideWithValue(socket),
        currentPositionFetcherProvider.overrideWithValue(
          () async => const DeviceLatLng(latitude: -25.3, longitude: -57.6),
        ),
        accessTokenReaderProvider.overrideWithValue(
          () async => 'a-real-token',
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'carga la lista de profesionales cercanos usando la posición actual y conecta el socket',
    () async {
      // Act
      final result = await container.read(
        nearbyProfessionalsControllerProvider.future,
      );

      // Assert
      expect(result, [_professional]);
      verify(
        () => repository.fetchNearby(latitude: -25.3, longitude: -57.6),
      ).called(1);
      expect(socket.connected, true);
    },
  );

  test(
    'actualiza la posición de un profesional cuando llega un evento en vivo',
    () async {
      // Arrange
      await container.read(nearbyProfessionalsControllerProvider.future);

      // Act
      socket.emit(
        const ProfessionalLocationUpdate(
          professionalId: 1,
          latitude: -25.1,
          longitude: -57.1,
        ),
      );
      final updated =
          container.read(nearbyProfessionalsControllerProvider).value!;

      // Assert
      expect(updated.single.latitude, -25.1);
      expect(updated.single.longitude, -57.1);
    },
  );

  test('ignora eventos de profesionales que no están en la lista', () async {
    // Arrange
    await container.read(nearbyProfessionalsControllerProvider.future);

    // Act
    socket.emit(
      const ProfessionalLocationUpdate(
        professionalId: 999,
        latitude: -1,
        longitude: -1,
      ),
    );
    final state = container.read(nearbyProfessionalsControllerProvider).value!;

    // Assert
    expect(state, [_professional]);
  });
}
