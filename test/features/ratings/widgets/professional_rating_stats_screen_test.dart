import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart';
import 'package:tekoapp_mobile/features/ratings/models/professional_rating_stats.dart';
import 'package:tekoapp_mobile/features/ratings/providers/professional_rating_stats_provider.dart';
import 'package:tekoapp_mobile/features/ratings/widgets/professional_rating_stats_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

const _profile = ProfessionalProfile(
  id: 5,
  referenceId: 'prof-uuid-1',
  categoryId: 3,
  description: 'Plomero',
  hourlyRate: 50000,
  status: ProfessionalStatus.approved,
  isAvailable: true,
  isOnline: true,
);

Future<void> _pumpScreen(
  WidgetTester tester, {
  required ProfessionalRatingStats stats,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myProfessionalProfileProvider.overrideWith(
          (ref) => Future.value(_profile),
        ),
        professionalRatingStatsProvider(
          _profile.id,
        ).overrideWith((ref) => Future.value(stats)),
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
        home: ProfessionalRatingStatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'muestra el promedio general, el total y la distribución por estrellas',
    (tester) async {
      // Arrange & Act
      await _pumpScreen(
        tester,
        stats: const ProfessionalRatingStats(
          averageRating: 4.7,
          totalRatings: 12,
          ratingDistribution: {'1': 0, '2': 0, '3': 1, '4': 4, '5': 7},
          averageCriteria: {'puntualidad': 4.8},
        ),
      );

      // Assert
      expect(find.text('4.7'), findsOneWidget);
      expect(find.text('12 calificaciones'), findsOneWidget);
      expect(find.text('puntualidad'), findsOneWidget);
    },
  );

  testWidgets(
    'muestra un estado vacío cuando el profesional todavía no recibió calificaciones',
    (tester) async {
      // Arrange & Act
      await _pumpScreen(
        tester,
        stats: const ProfessionalRatingStats(
          averageRating: 0,
          totalRatings: 0,
          ratingDistribution: {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
          averageCriteria: {},
        ),
      );

      // Assert
      expect(
        find.text('Todavía no recibiste ninguna calificación'),
        findsOneWidget,
      );
    },
  );
}
