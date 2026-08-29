import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/legal_consents/data/legal_consents_repository.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/ai_disclosure_entity_type.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/content_consent_grant.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/content_usage_scope.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/data_consents_history.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_consents_failure.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_document_type.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_document_version.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/user_consent.dart';
import 'package:tekoapp_mobile/features/legal_consents/providers/legal_consents_repository_provider.dart';
import 'package:tekoapp_mobile/features/legal_consents/widgets/privacy_and_data_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockLegalConsentsRepository extends Mock
    implements LegalConsentsRepository {}

final _grant = ContentConsentGrant(
  referenceId: 'grant-1',
  contentType: AiDisclosureEntityType.image,
  contentReferenceId: 'content-1',
  usageScope: ContentUsageScope.publicProfileDisplay,
  grantedAt: DateTime(2026, 8, 1),
  revokedAt: null,
);

final _history = DataConsentsHistory(
  consents: [
    UserConsent(
      referenceId: 'consent-1',
      acceptedAt: DateTime(2026, 8, 1),
      legalDocumentVersion: LegalDocumentVersion(
        referenceId: 'ver-1',
        documentType: LegalDocumentType.termsOfService,
        countryId: null,
        version: '1.0.0',
        contentUrl: 'https://tekoapp.com.py/legal/tos-1.0.0',
        publishedAt: DateTime(2026, 8, 1),
        isActive: true,
      ),
    ),
  ],
  contentGrants: [_grant],
);

Future<void> _pumpScreen(
  WidgetTester tester,
  _MockLegalConsentsRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        legalConsentsRepositoryProvider.overrideWithValue(repository),
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
        home: PrivacyAndDataScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockLegalConsentsRepository repository;

  setUp(() {
    repository = _MockLegalConsentsRepository();
  });

  testWidgets('muestra el historial de aceptaciones y los grants activos', (
    tester,
  ) async {
    // Arrange
    when(
      () => repository.fetchDataConsentsHistory(),
    ).thenAnswer((_) async => _history);

    // Act
    await _pumpScreen(tester, repository);

    // Assert
    expect(find.text('Términos de servicio'), findsOneWidget);
    expect(find.byKey(const Key('privacy_data_grant_grant-1')), findsOneWidget);
  });

  testWidgets(
    'revocar con retención legal muestra el motivo específico, no un error genérico',
    (tester) async {
      // Arrange
      when(
        () => repository.fetchDataConsentsHistory(),
      ).thenAnswer((_) async => _history);
      when(() => repository.revokeContentConsent('content-1')).thenThrow(
        const LegalConsentsLegalHoldFailure(
          'Este contenido tiene una retención legal obligatoria',
        ),
      );
      await _pumpScreen(tester, repository);

      // Act
      await tester.tap(find.byKey(const Key('privacy_data_revoke_grant-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Revocar').last);
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Este contenido tiene una retención legal obligatoria'),
        findsOneWidget,
      );
    },
  );

  testWidgets('muestra los estados vacíos cuando no hay historial', (
    tester,
  ) async {
    // Arrange
    when(() => repository.fetchDataConsentsHistory()).thenAnswer(
      (_) async => const DataConsentsHistory(consents: [], contentGrants: []),
    );

    // Act
    await _pumpScreen(tester, repository);

    // Assert
    expect(
      find.text('Todavía no aceptaste ningún documento'),
      findsOneWidget,
    );
    expect(
      find.text('No tenés contenido con consentimiento de uso otorgado'),
      findsOneWidget,
    );
  });
}
