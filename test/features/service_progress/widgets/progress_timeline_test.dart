import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart';
import 'package:tekoapp_mobile/features/service_progress/models/service_progress_entry.dart';
import 'package:tekoapp_mobile/features/service_progress/providers/service_progress_provider.dart';
import 'package:tekoapp_mobile/features/service_progress/widgets/progress_timeline.dart';
import 'package:tekoapp_mobile/features/services/models/service.dart';
import 'package:tekoapp_mobile/features/services/models/service_status.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

const _professionalRef = 'prof-ref-1';

Service _service({required ServiceStatus status}) {
  return Service(
    id: 1,
    referenceId: 'svc-1',
    userId: 1,
    categoryId: 1,
    serviceTypeId: 1,
    title: 'Reparación',
    description: 'Necesito una reparación',
    status: status,
    latitude: -25.2,
    longitude: -57.5,
    address: 'Calle 1',
    isUrgent: false,
    createdAt: DateTime.utc(2026, 8, 27),
    professionalId: 5,
    professional: const ServiceProfessionalSummary(
      id: 5,
      referenceId: _professionalRef,
      firstName: 'Juan',
      lastName: 'Pérez',
    ),
  );
}

ProfessionalProfile _professionalProfile(String referenceId) {
  return ProfessionalProfile(
    id: 5,
    referenceId: referenceId,
    categoryId: 1,
    description: 'Plomero',
    hourlyRate: 50000,
    status: ProfessionalStatus.approved,
    isAvailable: true,
    isOnline: false,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Service service,
  required List<Override> overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ProgressTimeline(service: service)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'muestra el estado vacío cuando el servicio todavía no tiene entradas',
    (tester) async {
      // Arrange
      final service = _service(status: ServiceStatus.inProgress);

      // Act
      await _pump(
        tester,
        service: service,
        overrides: [
          serviceProgressProvider.overrideWith((ref, id) async => []),
          myProfessionalProfileProvider.overrideWith((ref) async => null),
        ],
      );

      // Assert
      expect(find.text('Todavía no hay avances registrados'), findsOneWidget);
    },
  );

  testWidgets('muestra la nota de una entrada existente', (tester) async {
    // Arrange
    final service = _service(status: ServiceStatus.inProgress);
    final entry = ServiceProgressEntry(
      referenceId: 'entry-1',
      note: 'Instalé la cañería nueva',
      images: const [],
      entryOrder: 1,
      createdAt: DateTime.utc(2026, 8, 27, 10),
      editWindowExpired: true,
    );

    // Act
    await _pump(
      tester,
      service: service,
      overrides: [
        serviceProgressProvider.overrideWith((ref, id) async => [entry]),
        myProfessionalProfileProvider.overrideWith((ref) async => null),
      ],
    );

    // Assert
    expect(find.text('Instalé la cañería nueva'), findsOneWidget);
  });

  testWidgets(
    'muestra el botón de agregar avance cuando el usuario es el profesional asignado y el servicio está en curso',
    (tester) async {
      // Arrange
      final service = _service(status: ServiceStatus.inProgress);

      // Act
      await _pump(
        tester,
        service: service,
        overrides: [
          serviceProgressProvider.overrideWith((ref, id) async => []),
          myProfessionalProfileProvider.overrideWith(
            (ref) async => _professionalProfile(_professionalRef),
          ),
        ],
      );

      // Assert
      expect(
        find.byKey(const Key('add_progress_entry_button_svc-1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'no muestra el botón de agregar avance cuando el usuario no es el profesional asignado',
    (tester) async {
      // Arrange
      final service = _service(status: ServiceStatus.inProgress);

      // Act
      await _pump(
        tester,
        service: service,
        overrides: [
          serviceProgressProvider.overrideWith((ref, id) async => []),
          myProfessionalProfileProvider.overrideWith(
            (ref) async => _professionalProfile('otro-profesional-ref'),
          ),
        ],
      );

      // Assert
      expect(
        find.byKey(const Key('add_progress_entry_button_svc-1')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'no muestra el botón de agregar avance si el servicio ya no está en curso',
    (tester) async {
      // Arrange
      final service = _service(status: ServiceStatus.completed);

      // Act
      await _pump(
        tester,
        service: service,
        overrides: [
          serviceProgressProvider.overrideWith((ref, id) async => []),
          myProfessionalProfileProvider.overrideWith(
            (ref) async => _professionalProfile(_professionalRef),
          ),
        ],
      );

      // Assert
      expect(
        find.byKey(const Key('add_progress_entry_button_svc-1')),
        findsNothing,
      );
    },
  );
}
