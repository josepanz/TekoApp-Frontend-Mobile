// Suite: componente TekoToast
// Casos: CP-MOB-UI-011..014 (ver test/qa/casos/CP-UI.md)
// Tipo: widget / a11y   Prioridad: P2
// Precondiciones: host con botón que dispara TekoToast.show
// Trazabilidad: U2
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_toast.dart';

Widget _host(void Function(BuildContext) onTap, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onTap(context),
          child: const Text('go'),
        ),
      ),
    ),
  );
}

void main() {
  group('TekoToast', () {
    for (final entry in {
      TekoToastVariant.success: Icons.check_circle_outline,
      TekoToastVariant.error: Icons.error_outline,
      TekoToastVariant.info: Icons.info_outline,
    }.entries) {
      testWidgets('variante ${entry.key.name} muestra mensaje e ícono', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            (c) => TekoToast.show(c, 'Hecho', variant: entry.key),
            theme: AppTheme.light,
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pump();
        expect(find.text('Hecho'), findsOneWidget);
        expect(find.byIcon(entry.value), findsOneWidget);
      });
    }

    testWidgets('anuncia como liveRegion', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host((c) => TekoToast.show(c, 'Guardado')));
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      final nodes = find.semantics.byLabel(RegExp('Guardado')).evaluate();
      expect(nodes, isNotEmpty);
      expect(
        nodes.any((n) => n.flagsCollection.isLiveRegion),
        isTrue,
        reason: nodes.map((n) => n.toString()).join(' | '),
      );
      handle.dispose();
    });

    testWidgets('acción opcional se muestra y dispara el callback', (
      tester,
    ) async {
      var undone = false;
      await tester.pumpWidget(
        _host(
          (c) => TekoToast.show(
            c,
            'Eliminado',
            actionLabel: 'Deshacer',
            onAction: () => undone = true,
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      await tester.tap(find.text('Deshacer'));
      expect(undone, isTrue);
    });

    testWidgets('sin onAction no hay acción aunque haya label', (tester) async {
      await tester.pumpWidget(
        _host((c) => TekoToast.show(c, 'x', actionLabel: 'Deshacer')),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.byType(SnackBarAction), findsNothing);
    });

    testWidgets('funciona en dark mode', (tester) async {
      await tester.pumpWidget(
        _host(
          (c) => TekoToast.show(c, 'Oscuro', variant: TekoToastVariant.error),
          theme: AppTheme.dark,
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.text('Oscuro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
