import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/professional_profile/data/professional_profile_repository.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile_failure.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ProfessionalProfileRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = ProfessionalProfileRepository(ApiClient(dio: dio));
  });

  group('fetchMe', () {
    test('devuelve el perfil cuando el usuario ya tiene uno', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/professionals/me'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/professionals/me'),
          data: {
            'id': 2,
            'referenceId': 'prof-uuid-1',
            'categoryId': 3,
            'description': 'Plomero con 5 años de experiencia',
            'hourlyRate': 50000,
            'fixedRate': null,
            'skills': ['soldadura'],
            'yearsOfExperience': 5,
            'status': 'PENDING',
            'isAvailable': false,
            'isOnline': false,
          },
        ),
      );

      // Act
      final result = await repository.fetchMe();

      // Assert
      expect(result, isNotNull);
      expect(result!.status, ProfessionalStatus.pending);
      expect(result.categoryId, 3);
    });

    test('devuelve null cuando el usuario todavía no tiene perfil (404)',
        () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/professionals/me'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/professionals/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/professionals/me'),
            statusCode: 404,
          ),
        ),
      );

      // Act
      final result = await repository.fetchMe();

      // Assert
      expect(result, isNull);
    });

    test('lanza ProfessionalProfileServiceUnavailableFailure ante un 5xx',
        () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/professionals/me'),
      ).thenThrow(
        DioException(requestOptions: RequestOptions(path: '/professionals/me')),
      );

      // Act & Assert
      await expectLater(
        repository.fetchMe(),
        throwsA(isA<ProfessionalProfileServiceUnavailableFailure>()),
      );
    });
  });

  group('register', () {
    test('crea el perfil con los campos provistos', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/professionals',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/professionals'),
          data: {
            'id': 2,
            'referenceId': 'prof-uuid-1',
            'categoryId': 3,
            'description': 'Plomero',
            'hourlyRate': 50000,
            'fixedRate': null,
            'skills': <String>[],
            'yearsOfExperience': null,
            'status': 'PENDING',
            'isAvailable': false,
            'isOnline': false,
          },
        ),
      );

      // Act
      final result = await repository.register(
        categoryId: 3,
        description: 'Plomero',
        hourlyRate: 50000,
      );

      // Assert
      expect(result.categoryId, 3);
      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/professionals',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured.containsKey('fixedRate'), isFalse);
      expect(captured.containsKey('skills'), isFalse);
    });

    test(
      'lanza ProfessionalProfileValidationFailure cuando el usuario ya es profesional',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>(
            '/professionals',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/professionals'),
            response: Response(
              requestOptions: RequestOptions(path: '/professionals'),
              statusCode: 400,
            ),
          ),
        );

        // Act & Assert
        await expectLater(
          repository.register(
            categoryId: 3,
            description: 'Plomero',
            hourlyRate: 50000,
          ),
          throwsA(isA<ProfessionalProfileValidationFailure>()),
        );
      },
    );
  });
}
