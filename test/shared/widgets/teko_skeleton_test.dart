// Suite: componente TekoSkeleton y AsyncStateView.loadingBuilder
// Casos: CP-MOB-UI-001..006 (ver test/qa/casos/CP-UI.md)
// Tipo: widget / a11y   Prioridad: P2
// Precondiciones: widget aislado; reduce-motion y dark controlados
// Trazabilidad: U1
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';
import 'package:tekoapp_mobile/shared/widgets/async_state_view.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_skeleton.dart';

Widget _wrap(
  Widget child, {
  bool disableAnimations = false,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme,
    locale: const Locale('es'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
      ),
      child: app!,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TekoSkeleton', () {
    testWidgets('variante list renderiza itemCount cards', (tester) async {
      await tester.pumpWidget(
        _wrap(const TekoSkeleton.list(itemCount: 3, height: 80)),
      );
      expect(find.byType(TekoSkeleton), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(DecoratedBox), findsWidgets);
    });

    testWidgets('anuncia un único "Cargando" y excluye el subárbol', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const TekoSkeleton.card()));
      expect(find.bySemanticsLabel('Cargando'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('anima por defecto y se detiene con reduce-motion', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const TekoSkeleton.line(width: 100)));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(
        _wrap(const TekoSkeleton.line(width: 100), disableAnimations: true),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('renderiza en dark mode sin errores', (tester) async {
      await tester.pumpWidget(
        _wrap(const TekoSkeleton.card(), theme: AppTheme.dark),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('AsyncStateView usa loadingBuilder cuando se pasa', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AsyncStateView<int>(
            isLoading: true,
            hasError: false,
            data: null,
            loadingBuilder: (_) => const TekoSkeleton.line(),
            builder: (context, data) => Text('$data'),
          ),
          disableAnimations: true,
        ),
      );
      expect(find.byType(TekoSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('AsyncStateView sin loadingBuilder mantiene el spinner', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AsyncStateView<int>(
            isLoading: true,
            hasError: false,
            data: null,
            builder: (context, data) => Text('$data'),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
