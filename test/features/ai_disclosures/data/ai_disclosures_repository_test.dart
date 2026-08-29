import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/ai_disclosures/data/ai_disclosures_repository.dart';
import 'package:tekoapp_mobile/features/ai_disclosures/models/ai_disclosure_failure.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/ai_disclosure_entity_type.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late AiDisclosuresRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = AiDisclosuresRepository(ApiClient(dio: dio));
  });

  DioException errorResponse(
    String path, {
    required int statusCode,
    String backendMessage = 'x',
  }) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
        data: {
          'success': false,
          'error': {'code': statusCode, 'message': backendMessage},
        },
      ),
    );
  }

  Map<String, dynamic> disclosureJson() => {
        'referenceId': 'ai-1',
        'entityType': 'SERVICE_DESCRIPTION',
        'entityReferenceId': 'svc-1',
        'source': 'USER_DECLARED_AI',
        'aiProvider': null,
        'declaredByUserId': 5,
        'note': null,
        'createdAt': '2026-08-25T10:00:00.000Z',
      };

  group('declare', () {
    test('debe declarar el disclosure de contenido propio', () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/ai-disclosures',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/ai-disclosures'),
          data: disclosureJson(),
        ),
      );

      // Act
      final result = await repository.declare(
        entityType: AiDisclosureEntityType.serviceDescription,
        entityReferenceId: 'svc-1',
      );

      // Assert
      expect(result.referenceId, 'ai-1');
    });

    test(
        'debe lanzar AiDisclosureForbiddenFailure cuando el backend responde 403',
        () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/ai-disclosures',
          data: any(named: 'data'),
        ),
      ).thenThrow(errorResponse('/ai-disclosures', statusCode: 403));

      // Act & Assert
      await expectLater(
        repository.declare(
          entityType: AiDisclosureEntityType.serviceDescription,
          entityReferenceId: 'svc-de-otro',
        ),
        throwsA(isA<AiDisclosureForbiddenFailure>()),
      );
    });

    test(
        'debe lanzar AiDisclosureValidationFailure cuando el backend responde 400',
        () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/ai-disclosures',
          data: any(named: 'data'),
        ),
      ).thenThrow(errorResponse('/ai-disclosures', statusCode: 400));

      // Act & Assert
      await expectLater(
        repository.declare(
          entityType: AiDisclosureEntityType.budgetOption,
          entityReferenceId: 'budget-1',
        ),
        throwsA(isA<AiDisclosureValidationFailure>()),
      );
    });
  });

  group('fetch', () {
    test('debe retornar null cuando no hay disclosure para el contenido',
        () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>?>(
          '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
          ),
          data: null,
        ),
      );

      // Act
      final result = await repository.fetch(
        AiDisclosureEntityType.serviceDescription,
        'svc-1',
      );

      // Assert
      expect(result, isNull);
    });

    test('debe mapear el disclosure existente', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>?>(
          '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
          ),
          data: disclosureJson(),
        ),
      );

      // Act
      final result = await repository.fetch(
        AiDisclosureEntityType.serviceDescription,
        'svc-1',
      );

      // Assert
      expect(result?.referenceId, 'ai-1');
    });
  });

  group('retract', () {
    test(
        'debe lanzar AiDisclosureNotFoundFailure cuando no hay declaración vigente',
        () async {
      // Arrange
      when(
        () => dio.delete<void>('/ai-disclosures/SERVICE_DESCRIPTION/svc-1'),
      ).thenThrow(
        errorResponse(
          '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
          statusCode: 404,
        ),
      );

      // Act & Assert
      await expectLater(
        repository.retract(AiDisclosureEntityType.serviceDescription, 'svc-1'),
        throwsA(isA<AiDisclosureNotFoundFailure>()),
      );
    });
  });
}
