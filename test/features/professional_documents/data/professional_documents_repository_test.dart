import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/professional_documents/data/professional_documents_repository.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ProfessionalDocumentsRepository repository;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = ProfessionalDocumentsRepository(ApiClient(dio: dio));
  });

  Response<Map<String, dynamic>> jsonResponse(
    String path,
    Map<String, dynamic> data,
  ) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  Map<String, dynamic> documentTypeJson() => {
        'referenceId': 'type-1',
        'code': 'BG_CHECK',
        'name': 'Antecedentes',
        'description': null,
        'category': 'BACKGROUND_CHECK',
        'isRequired': true,
        'validityDays': null,
        'requiresStaffReview': true,
        'isVisibleToClient': false,
        'sortOrder': 0,
        'isActive': true,
      };

  group('myDocuments', () {
    test('parsea la lista de estados con documento null cuando no cargó nada', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/professionals/me/documents'),
      ).thenAnswer(
        (_) async => jsonResponse('/professionals/me/documents', {
          'data': [
            {'documentType': documentTypeJson(), 'document': null},
          ],
        }),
      );

      // Act
      final result = await repository.myDocuments();

      // Assert
      expect(result, hasLength(1));
      expect(result.single.document, isNull);
    });
  });

  group('upload', () {
    test('manda el file y los campos correctos en un solo multipart', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/professionals/me/documents',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse('/professionals/me/documents', {
          'referenceId': 'doc-1',
          'professionalDocumentType': documentTypeJson(),
          'fileKey': 'abc.jpg',
          'status': 'PENDING',
          'createdAt': '2026-08-27T10:00:00.000Z',
        }),
      );

      // Act
      final result = await repository.upload(
        professionalDocumentTypeReferenceId: 'type-1',
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
      );

      // Assert
      expect(result.referenceId, 'doc-1');
      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/professionals/me/documents',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as FormData;
      expect(
        captured.fields.map((e) => e.key),
        contains('professionalDocumentTypeReferenceId'),
      );
      expect(captured.files.single.key, 'file');
    });

    test('lanza ProfessionalDocumentTypeNotApplicableFailure cuando el backend responde 404', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/professionals/me/documents',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/professionals/me/documents'),
          response: Response(
            requestOptions: RequestOptions(
              path: '/professionals/me/documents',
            ),
            statusCode: 404,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.upload(
          professionalDocumentTypeReferenceId: 'type-1',
          bytes: Uint8List.fromList([1]),
          filename: 'foto.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<ProfessionalDocumentTypeNotApplicableFailure>()),
      );
    });
  });

  group('isVerified', () {
    test('devuelve true cuando requiredDocumentsVerified es true', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/professionals/prof-1'),
      ).thenAnswer(
        (_) async => jsonResponse(
          '/professionals/prof-1',
          {'requiredDocumentsVerified': true},
        ),
      );

      // Act
      final result = await repository.isVerified('prof-1');

      // Assert
      expect(result, isTrue);
    });
  });
}
