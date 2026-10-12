import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_avatar.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_button.dart';
import 'package:tekoapp_mobile/shared/widgets/teko_input.dart';

import '../../helpers/semantics_finders.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('TekoButton deriva el label semántico del texto y expone id', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        TekoButton(
          label: 'Guardar',
          onPressed: () {},
          semanticsIdentifier: 'x.y.save_button',
        ),
      ),
    );
    expect(find.bySemanticsLabel('Guardar'), findsOneWidget);
    expect(bySemanticsId('x.y.save_button'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('TekoButton acepta semanticLabel explícito', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        TekoButton(
          label: 'OK',
          semanticLabel: 'Confirmar pago',
          onPressed: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Confirmar pago'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('TekoInput se anuncia con su label y expone id', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(const TekoInput(label: 'Correo', semanticsIdentifier: 'a.b.email')),
    );
    expect(find.bySemanticsLabel('Correo'), findsOneWidget);
    expect(bySemanticsId('a.b.email'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('TekoAvatar tiene label y puede ser decorativo', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const TekoAvatar(name: 'Ana Pérez')));
    expect(find.bySemanticsLabel('Avatar de Ana Pérez'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(const TekoAvatar(name: 'Ana Pérez', decorative: true)),
    );
    expect(find.bySemanticsLabel('Avatar de Ana Pérez'), findsNothing);
    handle.dispose();
  });
}
