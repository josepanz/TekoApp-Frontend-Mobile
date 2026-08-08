import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/ratings/data/ratings_repository.dart';
import 'package:tekoapp_mobile/features/ratings/models/rating_failure.dart';
import 'package:tekoapp_mobile/features/ratings/models/rating_type.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late RatingsRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = RatingsRepository(ApiClient(dio: dio));
  });

  Response<T> okResponse<T>(String path, T data) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  Map<String, dynamic> ratingJson({String type = 'CLIENT_TO_PROFESSIONAL'}) => {
        'id': 'rating-uuid-1',
        'userId': 1,
        'professionalId': 2,
        'type': type,
        'rating': 5,
        'review': 'Excelente',
        'isAnonymous': false,
        'isActive': true,
        'createdAt': '2026-08-08T10:00:00.000Z',
      };

  group('rateProfessional', () {
    test('manda el professionalId y serviceRequestId como UUID', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/ratings',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => okResponse('/ratings', ratingJson()));

      // Act
      final result = await repository.rateProfessional(
        professionalReferenceId: 'prof-uuid-1',
        serviceReferenceId: 'svc-uuid-1',
        rating: 5,
      );

      // Assert
      expect(result.id, 'rating-uuid-1');
      final sentData = verify(
        () => dio.post<Map<String, dynamic>>(
          '/ratings',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(sentData['professionalId'], 'prof-uuid-1');
      expect(sentData['serviceRequestId'], 'svc-uuid-1');
      expect(sentData['type'], 'CLIENT_TO_PROFESSIONAL');
    });

    test('propaga el mensaje EXACTO cuando ya se calificó', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/ratings',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/ratings'),
          response: Response(
            requestOptions: RequestOptions(path: '/ratings'),
            statusCode: 400,
            data: {
              'success': false,
              'error': {'code': 400, 'message': 'Ya calificaste este servicio'},
            },
          ),
        ),
      );

      // Act
      try {
        await repository.rateProfessional(
          professionalReferenceId: 'prof-uuid-1',
          serviceReferenceId: 'svc-uuid-1',
          rating: 5,
        );
        fail('debía lanzar RatingValidationFailure');
      } on RatingValidationFailure catch (failure) {
        // Assert
        expect(failure.backendMessage, 'Ya calificaste este servicio');
      }
    });
  });

  group('rateClient', () {
    test('manda el clientId y serviceRequestId como UUID', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/ratings/professional-to-client',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => okResponse(
          '/ratings/professional-to-client',
          ratingJson(type: 'PROFESSIONAL_TO_CLIENT'),
        ),
      );

      // Act
      final result = await repository.rateClient(
        clientReferenceId: 'client-uuid-1',
        serviceReferenceId: 'svc-uuid-1',
        rating: 4,
      );

      // Assert
      expect(result.type, RatingType.professionalToClient);
      final sentData = verify(
        () => dio.post<Map<String, dynamic>>(
          '/ratings/professional-to-client',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(sentData['clientId'], 'client-uuid-1');
      expect(sentData['serviceRequestId'], 'svc-uuid-1');
    });
  });

  group('fetchForService', () {
    test('mapea las calificaciones existentes de un servicio', () async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>('/ratings/service/svc-uuid-1'),
      ).thenAnswer(
        (_) async => okResponse('/ratings/service/svc-uuid-1', [ratingJson()]),
      );

      // Act
      final result = await repository.fetchForService('svc-uuid-1');

      // Assert
      expect(result, hasLength(1));
      expect(result.single.type, RatingType.clientToProfessional);
    });

    test('devuelve una lista vacía cuando no hay calificaciones todavía',
        () async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>('/ratings/service/svc-uuid-1'),
      ).thenAnswer(
        (_) async => okResponse('/ratings/service/svc-uuid-1', []),
      );

      // Act
      final result = await repository.fetchForService('svc-uuid-1');

      // Assert
      expect(result, isEmpty);
    });
  });
}
