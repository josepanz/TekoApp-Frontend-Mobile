import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tekoapp_mobile/core/mode/app_mode.dart';
import 'package:tekoapp_mobile/core/mode/app_mode_provider.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart';
import 'package:tekoapp_mobile/features/professional_profile/widgets/professional_home_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

const _profile = ProfessionalProfile(
  id: 2,
  referenceId: 'prof-uuid-1',
  categoryId: 3,
  description: 'Plomero',
  hourlyRate: 50000,
  status: ProfessionalStatus.pending,
  isAvailable: false,
  isOnline: false,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required AsyncValue<ProfessionalProfile?> profileState,
}) async {
  final router = GoRouter(
    initialLocation: '/profesional',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/profesional',
        builder: (context, state) => const ProfessionalHomeScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myProfessionalProfileProvider.overrideWith((ref) {
          return switch (profileState) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future<ProfessionalProfile?>.error(
                error,
              ),
            _ => Completer<ProfessionalProfile?>().future,
          };
        }),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el perfil activo cuando ya existe uno', (
    tester,
  ) async {
    // Arrange & Act
    await _pumpScreen(tester, profileState: const AsyncData(_profile));

    // Assert
    expect(find.text('Tu perfil profesional está activo'), findsOneWidget);
  });

  testWidgets(
    'muestra un mensaje de servicio no disponible ante un error',
    (tester) async {
      // Arrange & Act
      await _pumpScreen(
        tester,
        profileState: AsyncError(Exception('caído'), StackTrace.empty),
      );

      // Assert
      expect(
        find.text(
          'No pudimos cargar tu perfil profesional — revisá tu conexión e intentá de nuevo',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'el botón "volver a modo cliente" resetea el modo y navega a home',
    (tester) async {
      // Arrange
      await _pumpScreen(tester, profileState: const AsyncData(_profile));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfessionalHomeScreen)),
      );
      container.read(appModeProvider.notifier).state = AppMode.professional;

      // Act
      await tester.tap(
        find.byKey(const Key('professional_home_back_to_client_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('home'), findsOneWidget);
      expect(container.read(appModeProvider), AppMode.client);
    },
  );
}
