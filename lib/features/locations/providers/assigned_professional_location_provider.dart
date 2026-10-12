import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/access_token_reader_provider.dart';
import '../models/locations_failure.dart';
import '../models/professional_last_location.dart';
import 'locations_repository_provider.dart';
import 'locations_socket_provider.dart';

/// Tracking en vivo del profesional asignado a un servicio ACCEPTED/IN_PROGRESS.
///
/// - Carga inicial: `GET /locations/professional/:id` (coordenada exacta, el backend la autoriza
///   por servicio activo). `null` = todavía no compartió ubicación (404 esperado).
/// - En vivo: se suscribe a la sala del profesional (`subscribeToProfessional`) y escucha
///   `exactLocationUpdated`. El `professionalId` es el `id` interno (Int) del profesional, el que
///   ya trae `Service.professionalId`. Se desuscribe al dispose (pantalla cerrada, otro servicio
///   o servicio terminado: `autoDispose` + family por profesional).
/// - Si el backend rechaza la suscripción (`subscriptionError`) cae a la posición APROXIMADA del
///   canal global `locationUpdated` — sin romper el stream.
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
  var useApproximateFallback = false;

  final exactSubscription = socket.exactLocationUpdates.listen((update) {
    if (update.professionalId != professionalId || controller.isClosed) return;
    controller.add(
      ProfessionalLastLocation(
        latitude: update.latitude,
        longitude: update.longitude,
      ),
    );
  });
  final errorSubscription = socket.subscriptionErrors.listen((error) {
    if (error.professionalId == professionalId) useApproximateFallback = true;
  });
  socket.onLocationUpdated((update) {
    if (!useApproximateFallback ||
        disposed ||
        controller.isClosed ||
        update.professionalId != professionalId) {
      return;
    }
    controller.add(
      ProfessionalLastLocation(
        latitude: update.latitude,
        longitude: update.longitude,
      ),
    );
  });

  socket.subscribeToProfessional(professionalId);
  ref.onDispose(() {
    unawaited(exactSubscription.cancel());
    unawaited(errorSubscription.cancel());
    socket.unsubscribeFromProfessional(professionalId);
    unawaited(controller.close());
  });
  yield* controller.stream;
});
