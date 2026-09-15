import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/models/portfolio_item.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/models/portfolio_review_status.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/providers/my_portfolio_provider.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/providers/portfolio_file_url_provider.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/widgets/my_portfolio_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required List<PortfolioItem> items,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myPortfolioProvider.overrideWith((ref) async => items),
        // Nunca resuelve: evita renderizar `Image.network` en el test (mismo criterio que
        // `teko_avatar_test.dart` — no vale la pena mockear la carga de imagen de red).
        portfolioFileUrlProvider
            .overrideWith((ref, key) => Completer<String>().future),
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
        home: MyPortfolioScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el estado vacío cuando todavía no subió ninguna foto', (
    tester,
  ) async {
    // Arrange & Act
    await _pump(tester, items: []);

    // Assert
    expect(
      find.text('Todavía no subiste ninguna foto de trabajos anteriores'),
      findsOneWidget,
    );
  });

  testWidgets('muestra el caption y el estado de una foto pendiente', (
    tester,
  ) async {
    // Arrange
    final item = PortfolioItem(
      referenceId: 'portfolio-1',
      fileKey: 'abc.jpg',
      caption: 'Instalación de cañerías',
      sortOrder: 0,
      isVisible: true,
      status: PortfolioReviewStatus.pending,
      createdAt: DateTime.utc(2026, 9, 1),
    );

    // Act
    await _pump(tester, items: [item]);

    // Assert
    expect(find.text('Instalación de cañerías'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('muestra el motivo de rechazo cuando la foto fue rechazada', (
    tester,
  ) async {
    // Arrange
    final item = PortfolioItem(
      referenceId: 'portfolio-1',
      fileKey: 'abc.jpg',
      sortOrder: 0,
      isVisible: true,
      status: PortfolioReviewStatus.rejected,
      rejectionReason: 'Foto borrosa',
      createdAt: DateTime.utc(2026, 9, 1),
    );

    // Act
    await _pump(tester, items: [item]);

    // Assert
    expect(find.text('Rechazado'), findsOneWidget);
    expect(find.text('Foto borrosa'), findsOneWidget);
  });
}
