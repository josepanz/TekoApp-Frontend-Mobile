import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/professional_documents/data/professional_documents_repository.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document_failure.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document_type.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/document_category.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/document_review_status.dart';
import 'package:tekoapp_mobile/features/professional_documents/providers/professional_documents_repository_provider.dart';
import 'package:tekoapp_mobile/features/professional_documents/providers/upload_document_controller_provider.dart';

class _MockProfessionalDocumentsRepository extends Mock
    implements ProfessionalDocumentsRepository {}

void main() {
  late _MockProfessionalDocumentsRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = _MockProfessionalDocumentsRepository();
    container = ProviderContainer(
      overrides: [
        professionalDocumentsRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('sube el documento con los datos recibidos', () async {
    // Arrange
    when(
      () => repository.upload(
        professionalDocumentTypeReferenceId: any(
          named: 'professionalDocumentTypeReferenceId',
        ),
        bytes: any(named: 'bytes'),
        filename: any(named: 'filename'),
        mimeType: any(named: 'mimeType'),
        issuedAt: any(named: 'issuedAt'),
      ),
    ).thenAnswer(
      (_) async => ProfessionalDocument(
        referenceId: 'doc-1',
        professionalDocumentType: const ProfessionalDocumentType(
          referenceId: 'type-1',
          code: 'BG_CHECK',
          name: 'Antecedentes',
          category: DocumentCategory.backgroundCheck,
          isRequired: true,
          requiresStaffReview: true,
          isVisibleToClient: false,
          sortOrder: 0,
          isActive: true,
        ),
        fileKey: 'abc.jpg',
        status: DocumentReviewStatus.pending,
        createdAt: DateTime.utc(2026, 8, 27),
      ),
    );

    // Act
    await container.read(uploadDocumentControllerProvider.notifier).submit(
          professionalDocumentTypeReferenceId: 'type-1',
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'foto.jpg',
          mimeType: 'image/jpeg',
        );

    // Assert
    final state = container.read(uploadDocumentControllerProvider);
    expect(state.hasError, isFalse);
    verify(
      () => repository.upload(
        professionalDocumentTypeReferenceId: 'type-1',
        bytes: any(named: 'bytes'),
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
        issuedAt: null,
      ),
    ).called(1);
  });

  test('deja el estado en error cuando el tipo no aplica (404)', () async {
    // Arrange
    when(
      () => repository.upload(
        professionalDocumentTypeReferenceId: any(
          named: 'professionalDocumentTypeReferenceId',
        ),
        bytes: any(named: 'bytes'),
        filename: any(named: 'filename'),
        mimeType: any(named: 'mimeType'),
        issuedAt: any(named: 'issuedAt'),
      ),
    ).thenThrow(const ProfessionalDocumentTypeNotApplicableFailure(null));

    // Act
    await container.read(uploadDocumentControllerProvider.notifier).submit(
          professionalDocumentTypeReferenceId: 'type-1',
          bytes: Uint8List.fromList([1]),
          filename: 'foto.jpg',
          mimeType: 'image/jpeg',
        );

    // Assert
    final state = container.read(uploadDocumentControllerProvider);
    expect(state.error, isA<ProfessionalDocumentTypeNotApplicableFailure>());
  });
}
