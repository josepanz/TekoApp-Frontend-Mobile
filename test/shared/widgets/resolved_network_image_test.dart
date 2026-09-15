import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/shared/widgets/resolved_network_image.dart';

void main() {
  group('ResolvedNetworkImage', () {
    testWidgets(
      'mientras la URL todavía no resolvió, renderiza el placeholder estático (sin spinner)',
      (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: ResolvedNetworkImage(
                urlAsync: AsyncLoading<String>(),
                width: 72,
                height: 72,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(Container), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(Image), findsNothing);
      },
    );

    testWidgets(
      'cuando la resolución de la URL falló, renderiza el placeholder sin lanzar',
      (tester) async {
        // Arrange & Act
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: ResolvedNetworkImage(
                urlAsync: AsyncError<String>(
                  Exception('no se pudo resolver la URL'),
                  StackTrace.current,
                ),
                width: 72,
                height: 72,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(Container), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'el placeholder que arma errorBuilder (URL presignada vencida) se renderiza sin lanzar',
      (tester) async {
        // Arrange — el errorBuilder de Image.network no se puede disparar en tests sin mockear
        // una carga de red real (mismo criterio que teko_avatar_test.dart). Se testea en cambio
        // el widget exacto que ese callback devuelve, vía el método estático que ambos caminos
        // comparten.
        late Widget errorPlaceholder;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) {
                errorPlaceholder = ResolvedNetworkImage.placeholder(
                  context,
                  width: 72,
                  height: 72,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: errorPlaceholder),
          ),
        );

        // Assert
        expect(find.byType(Container), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
