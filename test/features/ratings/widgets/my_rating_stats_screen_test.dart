import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/ratings/models/user_rating_stats.dart';
import 'package:tekoapp_mobile/features/ratings/providers/my_rating_stats_provider.dart';
import 'package:tekoapp_mobile/features/ratings/widgets/my_rating_stats_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  required AsyncValue<UserRatingStats> statsState,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myRatingStatsProvider.overrideWith((ref) {
          return switch (statsState) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future<UserRatingStats>.error(error),
            _ => Future<UserRatingStats>.delayed(
                const Duration(days: 1),
              ),
          };
        }),
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
        home: MyRatingStatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'muestra las calificaciones dadas y recibidas con sus promedios',
    (tester) async {
      // Arrange & Act
      await _pumpScreen(
        tester,
        statsState: const AsyncData(
          UserRatingStats(
            givenRatings: 3,
            receivedRatings: 1,
            averageGivenRating: 4.5,
            averageReceivedRating: 5,
          ),
        ),
      );

      // Assert
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.textContaining('4.5'), findsOneWidget);
      expect(find.textContaining('5.0'), findsOneWidget);
    },
  );

  testWidgets('muestra un mensaje de error cuando falla la carga', (
    tester,
  ) async {
    // Arrange & Act
    await _pumpScreen(
      tester,
      statsState: AsyncError(Exception('caído'), StackTrace.empty),
    );

    // Assert
    expect(
      find.text('No se pudieron cargar tus calificaciones — intentá de nuevo'),
      findsOneWidget,
    );
  });
}
