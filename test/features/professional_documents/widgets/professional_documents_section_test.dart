import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/professional_documents/data/professional_documents_repository.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/document_category.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/document_review_status.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document_type.dart';
import 'package:tekoapp_mobile/features/professional_documents/providers/professional_documents_repository_provider.dart';
import 'package:tekoapp_mobile/features/professional_documents/widgets/professional_documents_section.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockProfessionalDocumentsRepository extends Mock
    implements ProfessionalDocumentsRepository {}

const _documentType = ProfessionalDocumentType(
  referenceId: 'type-1',
  code: 'BG_CHECK',
  name: 'Antecedentes',
  category: DocumentCategory.backgroundCheck,
  isRequired: true,
  requiresStaffReview: true,
  isVisibleToClient: true,
  sortOrder: 0,
  isActive: true,
);

Future<void> _pumpSection(
  WidgetTester tester,
  _MockProfessionalDocumentsRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        professionalDocumentsRepositoryProvider.overrideWithValue(repository),
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
        home: Scaffold(
          body: ProfessionalDocumentsSection(professionalReferenceId: 'prof-1'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockProfessionalDocumentsRepository repository;

  setUp(() {
    repository = _MockProfessionalDocumentsRepository();
    when(
      () => repository.isVerified('prof-1'),
    ).thenAnswer((_) async => true);
  });

  testWidgets(
    'muestra el botón de ver documento cuando el archivo todavía existe',
    (tester) async {
      // Arrange
      when(() => repository.publicDocuments('prof-1')).thenAnswer(
        (_) async => [
          ProfessionalDocument(
            referenceId: 'doc-1',
            professionalDocumentType: _documentType,
            status: DocumentReviewStatus.approved,
            createdAt: DateTime(2026, 8, 27),
            fileKey: 'abc.jpg',
          ),
        ],
      );

      // Act
      await _pumpSection(tester, repository);

      // Assert
      expect(
        find.byKey(const Key('view_professional_document_doc-1')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'oculta el botón de ver documento cuando fileKey es null (cuenta anonimizada por I-01)',
    (tester) async {
      // Arrange
      when(() => repository.publicDocuments('prof-1')).thenAnswer(
        (_) async => [
          ProfessionalDocument(
            referenceId: 'doc-1',
            professionalDocumentType: _documentType,
            status: DocumentReviewStatus.approved,
            createdAt: DateTime(2026, 8, 27),
          ),
        ],
      );

      // Act
      await _pumpSection(tester, repository);

      // Assert — el nombre del tipo de documento se sigue mostrando, solo se omite la acción.
      expect(find.text('Antecedentes'), findsOneWidget);
      expect(
        find.byKey(const Key('view_professional_document_doc-1')),
        findsNothing,
      );
    },
  );
}
