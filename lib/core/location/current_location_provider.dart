import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Coordenadas del dispositivo — tipo propio (no `Position` de `geolocator` directo) para que el
/// resto del código, incluidos los tests, no dependa de la forma completa de ese paquete.
class DeviceLatLng {
  const DeviceLatLng({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

sealed class LocationFailure implements Exception {
  const LocationFailure();
}

/// El servicio de ubicación del dispositivo está apagado (no es un problema de permisos).
class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure();
}

/// El usuario negó el permiso (una vez o "para siempre" — la UI no distingue, en ambos casos
/// necesita que el usuario habilite el permiso manualmente o cargue la dirección a mano).
class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure();
}

typedef CurrentPositionFetcher = Future<DeviceLatLng> Function();

/// Wrapper fino sobre `geolocator` (ver `openspec/decisions.md`) — expuesto como un provider de
/// función, no un `FutureProvider` autoejecutado, porque leer la ubicación es una acción disparada
/// por el usuario ("usar mi ubicación actual"), no una consulta que se dispara sola al entrar a la
/// pantalla. Los tests overridean este provider con un fake en vez de tocar `Geolocator` real.
final currentPositionFetcherProvider = Provider<CurrentPositionFetcher>((ref) {
  return _fetchCurrentPosition;
});

/// Compartido con `features/locations` (emisión de ubicación en vivo del profesional) — un solo
/// lugar que pide el permiso de ubicación en foreground, ver `.claude/rules/flutter-architecture.md`
/// (DRY).
Future<void> ensureLocationPermission() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationServiceDisabledFailure();
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const LocationPermissionDeniedFailure();
  }
}

/// Mismo motivo que `currentPositionFetcherProvider`: exponer el chequeo de permiso detrás de un
/// provider de función para que los tests lo overrideen en vez de tocar el `MethodChannel` real de
/// `geolocator`.
final ensureLocationPermissionProvider = Provider<Future<void> Function()>((
  ref,
) {
  return ensureLocationPermission;
});

typedef PositionStreamOpener = Stream<DeviceLatLng> Function();

/// Stream continuo (no una sola lectura) para emisión de ubicación en vivo — ver
/// `features/locations`. `distanceFilter` evita emitir en cada frame de GPS (ver
/// `openspec/specs/realtime-location.md`).
final devicePositionStreamProvider = Provider<PositionStreamOpener>((ref) {
  return () => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25,
        ),
      ).map(
        (position) => DeviceLatLng(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
});

Future<DeviceLatLng> _fetchCurrentPosition() async {
  await ensureLocationPermission();

  final position = await Geolocator.getCurrentPosition();
  return DeviceLatLng(
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
