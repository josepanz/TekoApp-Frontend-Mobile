import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/legal_consents/data/legal_consents_repository.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/legal_consents_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late LegalConsentsRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = LegalConsentsRepository(ApiClient(dio: dio));
  });

  DioException errorResponse(
    String path, {
    required int statusCode,
    String? errorCode,
    String backendMessage = 'x',
  }) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
        data: {
          'success': false,
          'error': {
            'code': statusCode,
            'message': backendMessage,
            if (errorCode != null) 'errorCode': errorCode,
          },
        },
      ),
    );
  }

  Map<String, dynamic> versionJson({String referenceId = 'ver-1'}) => {
        'referenceId': referenceId,
        'documentType': 'TERMS_OF_SERVICE',
        'countryId': null,
        'version': '1.0.0',
        'contentUrl': 'https://tekoapp.com.py/legal/tos-1.0.0',
        'publishedAt': '2026-08-01T00:00:00.000Z',
        'isActive': true,
      };

  group('fetchPendingConsents', () {
    test('debe mapear la lista de versiones pendientes', () async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/legal/consents/pending')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/legal/consents/pending'),
          data: [versionJson()],
        ),
      );

      // Act
      final result = await repository.fetchPendingConsents();

      // Assert
      expect(result, hasLength(1));
      expect(result.first.referenceId, 'ver-1');
    });

    test('debe lanzar LegalConsentsServiceUnavailableFailure en un 5xx',
        () async {
      // Arrange
      when(() => dio.get<List<dynamic>>('/legal/consents/pending')).thenThrow(
        errorResponse('/legal/consents/pending', statusCode: 500),
      );

      // Act & Assert
      await expectLater(
        repository.fetchPendingConsents(),
        throwsA(isA<LegalConsentsServiceUnavailableFailure>()),
      );
    });
  });

  group('acceptConsent', () {
    test('debe crear el consentimiento y devolverlo mapeado', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>('/legal/consents/ver-1/accept'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/legal/consents/ver-1/accept'),
          data: {
            'referenceId': 'consent-1',
            'acceptedAt': '2026-08-25T10:00:00.000Z',
            'legalDocumentVersion': versionJson(),
          },
        ),
      );

      // Act
      final result = await repository.acceptConsent('ver-1');

      // Assert
      expect(result.referenceId, 'consent-1');
    });

    test(
      'debe lanzar LegalConsentsNotFoundFailure si la versión no existe',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>('/legal/consents/ver-x/accept'),
        ).thenThrow(
          errorResponse('/legal/consents/ver-x/accept', statusCode: 404),
        );

        // Act & Assert
        await expectLater(
          repository.acceptConsent('ver-x'),
          throwsA(isA<LegalConsentsNotFoundFailure>()),
        );
      },
    );

    test(
      'debe lanzar LegalConsentsConflictFailure si ya fue aceptada (409 sin errorCode)',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>('/legal/consents/ver-1/accept'),
        ).thenThrow(
          errorResponse('/legal/consents/ver-1/accept', statusCode: 409),
        );

        // Act & Assert
        await expectLater(
          repository.acceptConsent('ver-1'),
          throwsA(isA<LegalConsentsConflictFailure>()),
        );
      },
    );
  });

  group('revokeContentConsent', () {
    test(
      'debe lanzar LegalConsentsLegalHoldFailure con el mensaje del backend en 409+errorCode',
      () async {
        // Arrange
        when(
          () => dio.delete<void>('/users/me/content/content-1/consent'),
        ).thenThrow(
          errorResponse(
            '/users/me/content/content-1/consent',
            statusCode: 409,
            errorCode: 'LEGAL_HOLD_ACTIVE',
            backendMessage:
                'Este contenido tiene una retención legal obligatoria',
          ),
        );

        // Act & Assert
        try {
          await repository.revokeContentConsent('content-1');
          fail('debía lanzar LegalConsentsLegalHoldFailure');
        } on LegalConsentsLegalHoldFailure catch (failure) {
          expect(
            failure.backendMessage,
            'Este contenido tiene una retención legal obligatoria',
          );
        }
      },
    );

    test(
      'debe completar sin error cuando la revocación es exitosa',
      () async {
        // Arrange
        when(
          () => dio.delete<void>('/users/me/content/content-1/consent'),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(
              path: '/users/me/content/content-1/consent',
            ),
          ),
        );

        // Act & Assert
        await expectLater(
          repository.revokeContentConsent('content-1'),
          completes,
        );
      },
    );
  });
}
