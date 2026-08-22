import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/access_token_reader_provider.dart';
import '../models/locations_failure.dart';
import '../models/professional_last_location.dart';
import 'locations_repository_provider.dart';
import 'locations_socket_provider.dart';

/// Tracking en vivo del profesional asignado a un servicio ACCEPTED/IN_PROGRESS — arranca con su
/// última posición conocida (`GET /locations/professional/:id`) y se actualiza con los eventos
/// `locationUpdated` del socket de `/locations`, igual que el mapa de cercanos (ver
/// `NearbyProfessionalsController`). `null` significa "el profesional todavía no compartió
/// ubicación" (404 esperado, no un error a mostrar).
final assignedProfessionalLocationProvider = StreamProvider.autoDispose
    .family<ProfessionalLastLocation?, int>((ref, professionalId) async* {
  // `autoDispose` puede tirar abajo este provider mientras alguno de los `await` de abajo está en
  // vuelo (pantalla cerrada antes de que resuelva el fetch inicial) — riverpod 2.x no expone
  // `ref.mounted` (recién en 3.x), así que se rastrea a mano para evitar el "Bad state: Tried to
  // read a provider from a ProviderContainer that was already disposed".
  var disposed = false;
  ref.onDispose(() => disposed = true);

  final repository = ref.watch(locationsRepositoryProvider);
  try {
    yield await repository.fetchProfessionalLocation(professionalId);
  } on LocationsFailure {
    yield null;
  }
  if (disposed) return;

  final token = await ref.read(accessTokenReaderProvider)();
  if (disposed || token == null) return;
  final socket = ref.read(locationsSocketServiceProvider);
  socket.connect(token);

  final controller = StreamController<ProfessionalLastLocation>();
  socket.onLocationUpdated((update) {
    if (update.professionalId != professionalId) return;
    controller.add(
      ProfessionalLastLocation(
        latitude: update.latitude,
        longitude: update.longitude,
      ),
    );
  });
  ref.onDispose(controller.close);
  yield* controller.stream;
});
