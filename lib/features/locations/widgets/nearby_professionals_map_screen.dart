import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/location/current_location_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../models/nearby_professional.dart';
import '../providers/nearby_professionals_provider.dart';

/// Centro del mapa — posición actual del dispositivo, resuelta aparte de
/// `nearbyProfessionalsControllerProvider` (que la usa para el fetch inicial) porque la pantalla
/// necesita el valor en sí para centrar `FlutterMap`, no solo para armar el request.
final mapCenterProvider = FutureProvider<DeviceLatLng>((ref) {
  return ref.read(currentPositionFetcherProvider)();
});

/// Mapa de profesionales cercanos (modo cliente) — `flutter_map` + tiles de OpenStreetMap (ver
/// `openspec/decisions.md`, sin costo ni API key). Las posiciones de los marcadores se actualizan
/// en vivo vía el socket de `/locations` (ver `NearbyProfessionalsController`).
class NearbyProfessionalsMapScreen extends ConsumerWidget {
  const NearbyProfessionalsMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final center = ref.watch(mapCenterProvider);
    final professionals = ref.watch(nearbyProfessionalsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nearbyProfessionalsMapTitle)),
      body: AsyncStateView<DeviceLatLng>(
        isLoading: center.isLoading,
        hasError: center.hasError,
        data: center.valueOrNull,
        errorMessage: l10n.nearbyProfessionalsMapError,
        builder: (context, deviceCenter) => AsyncStateView<List<NearbyProfessional>>(
          isLoading: professionals.isLoading,
          hasError: professionals.hasError,
          data: professionals.valueOrNull,
          isEmpty: (professionals.valueOrNull ?? const []).isEmpty,
          emptyMessage: l10n.nearbyProfessionalsMapEmpty,
          errorMessage: l10n.nearbyProfessionalsMapError,
          builder: (context, list) => FlutterMap(
            key: const Key('nearby_professionals_map'),
            options: MapOptions(
              initialCenter: ll.LatLng(
                deviceCenter.latitude,
                deviceCenter.longitude,
              ),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tekoapp.mobile',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: ll.LatLng(
                      deviceCenter.latitude,
                      deviceCenter.longitude,
                    ),
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                  for (final professional in list)
                    Marker(
                      key: Key(
                        'nearby_professional_marker_${professional.id}',
                      ),
                      point: ll.LatLng(
                        professional.latitude,
                        professional.longitude,
                      ),
                      child: Tooltip(
                        message: professional.description,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
