import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/document_category.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document_type.dart';

/// Migración a codegen (M-04) de `professional_documents` — ver
/// `openspec/changes/platform-hardening-2026-09/CODEGEN.md`. Hallazgos reales que expuso esta
/// migración: `ProfessionalDocument.fileKey` se casteaba a `String` no-nullable pese a que el
/// backend lo documenta como `string | null` (`null` tras la anonimización de I-01), y
/// `ProfessionalDocumentType` descartaba en silencio `countryId`/`professionalCategoryId`.
void main() {
  Map<String, dynamic> documentTypeJson({
    Object? countryId = 'absent',
    Object? professionalCategoryId = 'absent',
  }) =>
      {
        'referenceId': 'type-1',
        'code': 'BG_CHECK',
        'name': 'Antecedentes',
        'description': null,
        'category': 'BACKGROUND_CHECK',
        if (countryId != 'absent') 'countryId': countryId,
        if (professionalCategoryId != 'absent')
          'professionalCategoryId': professionalCategoryId,
        'isRequired': true,
        'validityDays': null,
        'requiresStaffReview': true,
        'isVisibleToClient': false,
        'sortOrder': 0,
        'isActive': true,
      };

  group('ProfessionalDocumentType.fromJson', () {
    test('countryId y professionalCategoryId son null cuando están ausentes',
        () {
      final type = ProfessionalDocumentType.fromJson(documentTypeJson());
      expect(type.countryId, isNull);
      expect(type.professionalCategoryId, isNull);
      expect(type.category, DocumentCategory.backgroundCheck);
    });

    test(
      'countryId y professionalCategoryId se parsean cuando el backend los manda',
      () {
        final type = ProfessionalDocumentType.fromJson(
          documentTypeJson(countryId: 1, professionalCategoryId: 3),
        );
        expect(type.countryId, 1);
        expect(type.professionalCategoryId, 3);
      },
    );
  });

  group('ProfessionalDocument.fromJson', () {
    test('fileKey se parsea normalmente cuando el documento tiene archivo', () {
      final document = ProfessionalDocument.fromJson({
        'referenceId': 'doc-1',
        'professionalDocumentType': documentTypeJson(),
        'fileKey': 'abc.jpg',
        'status': 'APPROVED',
        'createdAt': '2026-08-27T10:00:00.000Z',
      });
      expect(document.fileKey, 'abc.jpg');
    });

    test(
      'fileKey es null sin lanzar cuando la cuenta del profesional fue anonimizada (I-01)',
      () {
        final document = ProfessionalDocument.fromJson({
          'referenceId': 'doc-1',
          'professionalDocumentType': documentTypeJson(),
          'fileKey': null,
          'status': 'APPROVED',
          'createdAt': '2026-08-27T10:00:00.000Z',
        });
        expect(document.fileKey, isNull);
      },
    );
  });
}
