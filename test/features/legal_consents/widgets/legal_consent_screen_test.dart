import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/legal_consents/data/legal_consents_repository.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_document_type.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_document_version.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/user_consent.dart';
import 'package:tekoapp_mobile/features/legal_consents/providers/legal_consents_repository_provider.dart';
import 'package:tekoapp_mobile/features/legal_consents/widgets/legal_consent_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockLegalConsentsRepository extends Mock
    implements LegalConsentsRepository {}

final _version = LegalDocumentVersion(
  referenceId: 'ver-1',
  documentType: LegalDocumentType.termsOfService,
  countryId: null,
  version: '1.0.0',
  contentUrl: 'https://tekoapp.com.py/legal/tos-1.0.0',
  publishedAt: DateTime(2026, 8, 1),
  isActive: true,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  _MockLegalConsentsRepository repository,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/legal/consentimiento',
        builder: (context, state) => const LegalConsentScreen(),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        legalConsentsRepositoryProvider.overrideWithValue(repository),
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
  router.push('/legal/consentimiento');
  await tester.pumpAndSettle();
}

void main() {
  late _MockLegalConsentsRepository repository;

  setUp(() {
    repository = _MockLegalConsentsRepository();
  });

  testWidgets(
    'el botón de aceptar queda deshabilitado hasta marcar el checkbox',
    (tester) async {
      // Arrange
      when(
        () => repository.fetchPendingConsents(),
      ).thenAnswer((_) async => [_version]);
      await _pumpScreen(tester, repository);

      // Assert — deshabilitado antes de tildar
      final buttonFinder = find.byKey(
        const Key('legal_consent_accept_button'),
      );
      var button = tester.widget<ElevatedButton>(
        find.descendant(
          of: buttonFinder,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);

      // Act
      await tester.tap(find.byKey(const Key('legal_consent_checkbox_ver-1')));
      await tester.pumpAndSettle();

      // Assert — habilitado tras tildar
      button = tester.widget<ElevatedButton>(
        find.descendant(
          of: buttonFinder,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'aceptar llama al repositorio y, al vaciarse lo pendiente, resuelve la pantalla',
    (tester) async {
      // Arrange
      when(
        () => repository.fetchPendingConsents(),
      ).thenAnswer((_) async => [_version]);
      when(() => repository.acceptConsent('ver-1')).thenAnswer(
        (_) async => UserConsent(
          referenceId: 'consent-1',
          acceptedAt: DateTime(2026, 8, 25),
          legalDocumentVersion: _version,
        ),
      );
      await _pumpScreen(tester, repository);

      // Tras aceptar, la próxima carga de pendientes debe devolver vacío.
      when(
        () => repository.fetchPendingConsents(),
      ).thenAnswer((_) async => []);

      // Act
      await tester.tap(find.byKey(const Key('legal_consent_checkbox_ver-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('legal_consent_accept_button')));
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.acceptConsent('ver-1')).called(1);
    },
  );

  testWidgets('muestra el estado vacío cuando no hay documentos pendientes', (
    tester,
  ) async {
    // Arrange
    when(() => repository.fetchPendingConsents()).thenAnswer((_) async => []);

    // Act
    await _pumpScreen(tester, repository);

    // Assert
    expect(find.text('No tenés documentos pendientes'), findsOneWidget);
  });
}
