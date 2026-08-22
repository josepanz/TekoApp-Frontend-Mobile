import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/access_token_reader_provider.dart';
import '../../../core/location/current_location_provider.dart';
import '../../../core/realtime/locations_socket_service.dart';
import '../../professional_profile/providers/my_professional_profile_provider.dart';
import '../models/locations_failure.dart';
import 'locations_repository_provider.dart';
import 'locations_socket_provider.dart';

/// `true` = el profesional está online y emitiendo su ubicación en vivo (solo mientras la app está
/// en foreground — ver `openspec/decisions.md`, "Emisión de ubicación: alcance foreground-only").
/// El estado inicial refleja `ProfessionalProfile.isOnline` (lo que el backend ya sabe), no arranca
/// siempre en `false`.
class OnlineStatusController extends AsyncNotifier<bool> {
  StreamSubscription<DeviceLatLng>? _positionSubscription;
  // Cacheado, nunca releído con `ref` desde `_stopEmitting` — ese método corre también desde
  // `ref.onDispose`, donde el container ya puede estar cerrado y un `ref.read` ahí explota.
  LocationsSocketService? _socket;

  @override
  Future<bool> build() async {
    ref.onDispose(_stopEmitting);
    final profile = await ref.watch(myProfessionalProfileProvider.future);
    return profile?.isOnline ?? false;
  }

  Future<void> setOnline(bool next) async {
    state = const AsyncLoading<bool>().copyWithPrevious(state);
    try {
      await ref.read(locationsRepositoryProvider).setOnlineStatus(next);
      if (next) {
        await _startEmitting();
      } else {
        _stopEmitting();
      }
      state = AsyncData(next);
    } catch (error, stackTrace) {
      _stopEmitting();
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> _startEmitting() async {
    await ref.read(ensureLocationPermissionProvider)();

    final token = await ref.read(accessTokenReaderProvider)();
    if (token == null) {
      throw const LocationsServiceUnavailableFailure();
    }

    final socket = ref.read(locationsSocketServiceProvider);
    _socket = socket;
    socket.connect(token);

    final openStream = ref.read(devicePositionStreamProvider);
    _positionSubscription = openStream().listen((position) {
      socket.emitUpdateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  void _stopEmitting() {
    unawaited(_positionSubscription?.cancel());
    _positionSubscription = null;
    _socket?.disconnect();
    _socket = null;
  }
}

final onlineStatusControllerProvider =
    AsyncNotifierProvider<OnlineStatusController, bool>(
  OnlineStatusController.new,
);
