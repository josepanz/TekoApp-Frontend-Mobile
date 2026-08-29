import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/legal_consents/data/legal_consents_repository.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_consents_failure.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_document_type.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_document_version.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/user_consent.dart';
import 'package:tekoapp_mobile/features/legal_consents/providers/legal_consents_controller_provider.dart';
import 'package:tekoapp_mobile/features/legal_consents/providers/legal_consents_repository_provider.dart';
import 'package:tekoapp_mobile/features/legal_consents/providers/pending_consents_provider.dart';

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

void main() {
  late _MockLegalConsentsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _MockLegalConsentsRepository();
    when(() => repository.fetchPendingConsents()).thenAnswer((_) async => []);
    container = ProviderContainer(
      overrides: [
        legalConsentsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  test(
    'accept invalida pendingConsentsProvider y dataConsentsHistoryProvider',
    () async {
      // Arrange
      when(() => repository.acceptConsent('ver-1')).thenAnswer(
        (_) async => UserConsent(
          referenceId: 'consent-1',
          acceptedAt: DateTime(2026, 8, 25),
          legalDocumentVersion: _version,
        ),
      );
      container.read(pendingConsentsProvider);

      // Act
      await container
          .read(legalConsentsControllerProvider.notifier)
          .accept('ver-1');

      // Assert
      verify(() => repository.acceptConsent('ver-1')).called(1);
      final state = container.read(legalConsentsControllerProvider);
      expect(state.hasError, isFalse);
    },
  );

  test('accept expone el error cuando el repositorio falla', () async {
    // Arrange
    when(
      () => repository.acceptConsent('ver-1'),
    ).thenThrow(const LegalConsentsConflictFailure('ya aceptado'));

    // Act
    await container
        .read(legalConsentsControllerProvider.notifier)
        .accept('ver-1');

    // Assert
    final state = container.read(legalConsentsControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<LegalConsentsConflictFailure>());
  });

  test(
    'revoke expone LegalConsentsLegalHoldFailure sin tratarlo como error genérico',
    () async {
      // Arrange
      when(() => repository.revokeContentConsent('content-1')).thenThrow(
        const LegalConsentsLegalHoldFailure('retención legal'),
      );

      // Act
      await container
          .read(legalConsentsControllerProvider.notifier)
          .revoke('content-1');

      // Assert
      verify(() => repository.revokeContentConsent('content-1')).called(1);
      final state = container.read(legalConsentsControllerProvider);
      final error = state.error;
      expect(error, isA<LegalConsentsLegalHoldFailure>());
      expect(
        (error as LegalConsentsLegalHoldFailure).backendMessage,
        'retención legal',
      );
    },
  );
}
