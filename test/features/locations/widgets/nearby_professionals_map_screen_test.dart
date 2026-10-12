// Suite: pantalla de mapa de profesionales cercanos
// Casos: CP-MOB-LOC-008 (ver test/qa/casos/CP-LOC.md)
// Tipo: widget   Prioridad: P2
// Precondiciones: mapCenterProvider y controller de cercanos sobreescritos
// Trazabilidad: M8; aviso de ubicación aproximada
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/location/current_location_provider.dart';
import 'package:tekoapp_mobile/features/locations/models/nearby_professional.dart';
import 'package:tekoapp_mobile/features/locations/providers/nearby_professionals_provider.dart';
import 'package:tekoapp_mobile/features/locations/widgets/nearby_professionals_map_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

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
  isAvailable: true,
  averageRating: 4.5,
);

class _FixedNearbyController extends NearbyProfessionalsController {
  @override
  Future<List<NearbyProfessional>> build() async => const [_professional];
}

void main() {
  testWidgets('muestra el aviso de ubicación aproximada sobre el mapa', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapCenterProvider.overrideWith(
            (ref) async =>
                const DeviceLatLng(latitude: -25.3, longitude: -57.6),
          ),
          nearbyProfessionalsControllerProvider
              .overrideWith(_FixedNearbyController.new),
        ],
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: NearbyProfessionalsMapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const Key('nearby_professionals_approximate_notice')),
      findsOneWidget,
    );
    expect(
      find.text('Ubicación aproximada · solo profesionales en línea'),
      findsOneWidget,
    );
  });
}
