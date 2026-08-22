import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/core/auth/access_token_reader_provider.dart';
import 'package:tekoapp_mobile/core/location/current_location_provider.dart';
import 'package:tekoapp_mobile/core/realtime/locations_socket_service.dart';
import 'package:tekoapp_mobile/features/locations/providers/locations_socket_provider.dart';
import 'package:tekoapp_mobile/features/locations/providers/online_status_controller_provider.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart';

class _MockDio extends Mock implements Dio {}

class _FakeLocationsSocketService implements LocationsSocketService {
  bool connected = false;
  String? tokenUsed;
  final emitted = <Map<String, double>>[];

  @override
  void connect(String accessToken) {
    connected = true;
    tokenUsed = accessToken;
  }

  @override
  void disconnect() => connected = false;

  @override
  void emitUpdateLocation({
    required double latitude,
    required double longitude,
  }) {
    emitted.add({'latitude': latitude, 'longitude': longitude});
  }

  @override
  void onLocationUpdated(void Function(ProfessionalLocationUpdate) listener) {}
}

const _profile = ProfessionalProfile(
  id: 1,
  referenceId: 'prof-ref-1',
  categoryId: 3,
  description: 'desc',
  hourlyRate: 50000,
  status: ProfessionalStatus.approved,
  isAvailable: true,
  isOnline: false,
);

void main() {
  late _MockDio dio;
  late _FakeLocationsSocketService socket;
  late StreamController<DeviceLatLng> positionController;
  late ProviderContainer container;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    socket = _FakeLocationsSocketService();
    positionController = StreamController<DeviceLatLng>.broadcast();

    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        myProfessionalProfileProvider.overrideWith((ref) async => _profile),
        locationsSocketServiceProvider.overrideWithValue(socket),
        ensureLocationPermissionProvider.overrideWithValue(() async {}),
        accessTokenReaderProvider.overrideWithValue(
          () async => 'a-real-token',
        ),
        devicePositionStreamProvider.overrideWithValue(
          () => positionController.stream,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    positionController.close();
  });

  test('el estado inicial refleja isOnline del perfil profesional', () async {
    // Act
    final result = await container.read(
      onlineStatusControllerProvider.future,
    );

    // Assert
    expect(result, false);
  });

  test(
    'setOnline(true) conecta el socket y emite cada posición nueva',
    () async {
      // Arrange
      when(
        () => dio.patch<void>('/locations/online', data: {'isOnline': true}),
      ).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: '/locations/online')),
      );
      await container.read(onlineStatusControllerProvider.future);
      final notifier = container.read(onlineStatusControllerProvider.notifier);

      // Act
      await notifier.setOnline(true);
      positionController.add(
        const DeviceLatLng(latitude: -25.3, longitude: -57.6),
      );
      await Future<void>.delayed(Duration.zero);

      // Assert
      expect(container.read(onlineStatusControllerProvider).value, true);
      expect(socket.connected, true);
      expect(socket.tokenUsed, 'a-real-token');
      expect(socket.emitted, [
        {'latitude': -25.3, 'longitude': -57.6},
      ]);
    },
  );

  test('setOnline(false) desconecta el socket', () async {
    // Arrange — primero online, para que el controller tenga una conexión activa que cerrar
    when(
      () => dio.patch<void>('/locations/online', data: {'isOnline': true}),
    ).thenAnswer(
      (_) async =>
          Response(requestOptions: RequestOptions(path: '/locations/online')),
    );
    when(
      () => dio.patch<void>('/locations/online', data: {'isOnline': false}),
    ).thenAnswer(
      (_) async =>
          Response(requestOptions: RequestOptions(path: '/locations/online')),
    );
    await container.read(onlineStatusControllerProvider.future);
    final notifier = container.read(onlineStatusControllerProvider.notifier);
    await notifier.setOnline(true);

    // Act
    await notifier.setOnline(false);

    // Assert
    expect(container.read(onlineStatusControllerProvider).value, false);
    expect(socket.connected, false);
  });

  test('si el backend rechaza el cambio, el estado queda en error', () async {
    // Arrange
    when(
      () => dio.patch<void>('/locations/online', data: {'isOnline': true}),
    ).thenThrow(
      DioException(requestOptions: RequestOptions(path: '/locations/online')),
    );
    await container.read(onlineStatusControllerProvider.future);
    final notifier = container.read(onlineStatusControllerProvider.notifier);

    // Act
    await notifier.setOnline(true);

    // Assert
    expect(container.read(onlineStatusControllerProvider).hasError, true);
    expect(socket.connected, false);
  });
}
