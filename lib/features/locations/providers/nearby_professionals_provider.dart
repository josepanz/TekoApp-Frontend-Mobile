import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/access_token_reader_provider.dart';
import '../../../core/location/current_location_provider.dart';
import '../../../core/realtime/locations_socket_service.dart';
import '../models/nearby_professional.dart';
import 'locations_repository_provider.dart';
import 'locations_socket_provider.dart';

/// Mapa de profesionales cercanos (modo cliente) — carga inicial vía `GET /locations/nearby`
/// centrada en la posición actual del dispositivo, y las posiciones se actualizan en vivo con los
/// eventos `locationUpdated` del socket de `/locations` — el cliente solo escucha, nunca emite
/// (ver `LocationsGateway.handleConnection`, acepta conexiones de usuarios sin perfil profesional).
///
/// La conexión del socket es compartida con `OnlineStatusController` (instancia única de
/// `locationsSocketServiceProvider`, ver ese provider) — este controller nunca la desconecta al
/// salir de la pantalla, para no cortar la emisión de un profesional que esté online al mismo
/// tiempo con la misma cuenta.
class NearbyProfessionalsController
    extends AsyncNotifier<List<NearbyProfessional>> {
  @override
  Future<List<NearbyProfessional>> build() async {
    final position = await ref.read(currentPositionFetcherProvider)();
    final professionals = await ref
        .read(locationsRepositoryProvider)
        .fetchNearby(
          latitude: position.latitude,
          longitude: position.longitude,
        );
    await _listenForLiveUpdates();
    return professionals;
  }

  Future<void> _listenForLiveUpdates() async {
    final token = await ref.read(accessTokenReaderProvider)();
    if (token == null) return;
    final socket = ref.read(locationsSocketServiceProvider);
    socket.connect(token);
    socket.onLocationUpdated(_applyUpdate);
  }

  void _applyUpdate(ProfessionalLocationUpdate update) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final professional in current)
        if (professional.id == update.professionalId)
          professional.copyWithPosition(
            latitude: update.latitude,
            longitude: update.longitude,
          )
        else
          professional,
    ]);
  }
}

final nearbyProfessionalsControllerProvider = AsyncNotifierProvider<
    NearbyProfessionalsController, List<NearbyProfessional>>(
  NearbyProfessionalsController.new,
);
