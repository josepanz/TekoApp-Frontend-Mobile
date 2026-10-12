// Suite: componente TekoEmptyState
// Casos: CP-MOB-UI-007..010 (ver test/qa/casos/CP-UI.md)
// Tipo: widget / a11y   Prioridad: P2
// Precondiciones: widget aislado en MaterialApp
// Trazabilidad: U2
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';
import 'package:tekoapp_mobile/shared/widgets/async_state_view.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('TekoEmptyState', () {
    testWidgets('muestra ícono, título y descripción sin CTA', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TekoEmptyState(
            title: 'Sin pagos',
            description: 'Cuando pagues algo aparece acá',
            icon: Icons.history,
          ),
        ),
      );
      expect(find.text('Sin pagos'), findsOneWidget);
      expect(find.text('Cuando pagues algo aparece acá'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('el CTA dispara onAction y cumple tap target', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          TekoEmptyState(
            title: 'Vacío',
            actionLabel: 'Crear',
            onAction: () => taps++,
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.tap(find.text('Crear'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('el título se anuncia como una unidad semántica', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const TekoEmptyState(title: 'Vacío', icon: Icons.history)),
      );
      expect(find.bySemanticsLabel('Vacío'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('AsyncStateView lo usa para el estado vacío', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AsyncStateView<List<int>>(
            isLoading: false,
            hasError: false,
            data: const [],
            isEmpty: true,
            emptyMessage: 'Nada por acá',
            emptyActionLabel: 'Agregar',
            onEmptyAction: () {},
            builder: (context, data) => const SizedBox(),
          ),
        ),
      );
      expect(find.byType(TekoEmptyState), findsOneWidget);
      expect(find.text('Nada por acá'), findsOneWidget);
      expect(find.text('Agregar'), findsOneWidget);
    });
  });
}
