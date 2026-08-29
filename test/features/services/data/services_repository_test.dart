import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/services/data/services_repository.dart';
import 'package:tekoapp_mobile/features/services/models/request_status.dart';
import 'package:tekoapp_mobile/features/services/models/service_failure.dart';
import 'package:tekoapp_mobile/features/services/models/service_status.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ServicesRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = ServicesRepository(ApiClient(dio: dio));
  });

  Map<String, dynamic> serviceJson({
    String id = 'service-uuid-1',
    String status = 'PENDING',
  }) {
    return {
      'id': 1,
      'referenceId': id,
      'userId': 1,
      'professionalId': null,
      'categoryId': 3,
      'serviceTypeId': 4,
      'title': 'Reparación de cañería',
      'description': 'Se necesita reparar una cañería rota',
      'status': status,
      'estimatedHours': 2.5,
      'hourlyRate': 50000,
      'fixedPrice': null,
      'totalAmount': null,
      'finalAmount': null,
      'latitude': -25.2637,
      'longitude': -57.5759,
      'address': 'Av. España 1234, Asunción',
      'additionalNotes': null,
      'isUrgent': false,
      'startedAt': null,
      'completedAt': null,
      'cancelledAt': null,
      'cancellationReason': null,
      'createdAt': '2026-08-08T10:00:00.000Z',
      'category': null,
      'professional': null,
    };
  }

  Map<String, dynamic> serviceRequestJson({
    String id = 'request-uuid-1',
    String status = 'PENDING',
  }) {
    return {
      'id': 1,
      'referenceId': id,
      'serviceId': 'service-uuid-1',
      'professionalId': 2,
      'status': status,
      'proposedPrice': 120000,
      'proposedHours': 3.0,
      'message': 'Puedo atenderle esta tarde',
      'createdAt': '2026-08-08T10:00:00.000Z',
    };
  }

  DioException conflictError(String path) => DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 409,
        ),
      );

  DioException validationError(String path) => DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 400,
        ),
      );

  DioException networkError(String path) =>
      DioException(requestOptions: RequestOptions(path: path));

  group('createService', () {
    test('crea el servicio y devuelve el modelo mapeado', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services'),
          data: serviceJson(),
        ),
      );

      // Act
      final result = await repository.createService(
        title: 'Reparación de cañería',
        description: 'Se necesita reparar una cañería rota',
        categoryId: 3,
        serviceTypeId: 4,
        latitude: -25.2637,
        longitude: -57.5759,
        address: 'Av. España 1234, Asunción',
      );

      // Assert
      expect(result.referenceId, 'service-uuid-1');
      expect(result.status, ServiceStatus.pending);
    });

    test('omite del body los campos opcionales no provistos', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services'),
          data: serviceJson(),
        ),
      );

      // Act
      await repository.createService(
        title: 'Reparación de cañería',
        description: 'Se necesita reparar una cañería rota',
        categoryId: 3,
        serviceTypeId: 4,
        latitude: -25.2637,
        longitude: -57.5759,
        address: 'Av. España 1234, Asunción',
      );

      // Assert
      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/services',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured.containsKey('hourlyRate'), isFalse);
      expect(captured.containsKey('isUrgent'), isFalse);
    });

    test('lanza ServiceValidationFailure ante un 400', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services',
          data: any(named: 'data'),
        ),
      ).thenThrow(validationError('/services'));

      // Act & Assert
      await expectLater(
        repository.createService(
          title: 't',
          description: 'd',
          categoryId: 3,
          serviceTypeId: 4,
          latitude: 0,
          longitude: 0,
          address: 'a',
        ),
        throwsA(isA<ServiceValidationFailure>()),
      );
    });

    test('lanza ServiceServiceUnavailableFailure ante un error de red',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services',
          data: any(named: 'data'),
        ),
      ).thenThrow(networkError('/services'));

      // Act & Assert
      await expectLater(
        repository.createService(
          title: 't',
          description: 'd',
          categoryId: 3,
          serviceTypeId: 4,
          latitude: 0,
          longitude: 0,
          address: 'a',
        ),
        throwsA(isA<ServiceServiceUnavailableFailure>()),
      );
    });
  });

  group('fetchMyServices', () {
    test('manda el rol pedido y mapea el listado', () async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>(
          '/services/my-services',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/my-services'),
          data: [serviceJson()],
        ),
      );

      // Act
      final result = await repository.fetchMyServices(role: 'client');

      // Assert
      expect(result, hasLength(1));
      final captured = verify(
        () => dio.get<List<dynamic>>(
          '/services/my-services',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['role'], 'client');
      expect(captured.containsKey('status'), isFalse);
    });

    test('devuelve un estado vacío cuando no hay servicios todavía', () async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>(
          '/services/my-services',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/my-services'),
          data: [],
        ),
      );

      // Act
      final result = await repository.fetchMyServices(role: 'professional');

      // Assert
      expect(result, isEmpty);
    });
  });

  group('fetchServiceDetail', () {
    test('devuelve el detalle mapeado', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/service-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: serviceJson(),
        ),
      );

      // Act
      final result = await repository.fetchServiceDetail('service-uuid-1');

      // Assert
      expect(result.title, 'Reparación de cañería');
    });
  });

  group('fetchAvailableServices', () {
    test('filtra PENDING por la categoría del profesional', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>(
          '/services',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services'),
          data: {
            'data': [serviceJson()],
            'pagination': {
              'total': 1,
              'page': 1,
              'pageSize': 10,
              'totalPages': 1,
            },
          },
        ),
      );

      // Act
      final result = await repository.fetchAvailableServices(categoryId: 3);

      // Assert
      expect(result, hasLength(1));
      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          '/services',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['status'], 'PENDING');
      expect(captured['categoryId'], 3);
    });
  });

  group('fetchServiceRequests', () {
    test('mapea las propuestas del servicio', () async {
      // Arrange
      when(
        () =>
            dio.get<Map<String, dynamic>>('/services/service-uuid-1/requests'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/requests',
          ),
          data: {
            'data': [serviceRequestJson()],
          },
        ),
      );

      // Act
      final result = await repository.fetchServiceRequests('service-uuid-1');

      // Assert
      expect(result, hasLength(1));
      expect(result.single.status, RequestStatus.pending);
    });
  });

  group('proposeOnService', () {
    test('crea la propuesta con los campos provistos', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services/service-uuid-1/requests',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/requests',
          ),
          data: serviceRequestJson(),
        ),
      );

      // Act
      final result = await repository.proposeOnService(
        'service-uuid-1',
        proposedPrice: 120000,
      );

      // Assert
      expect(result.referenceId, 'request-uuid-1');
    });
  });

  group('respondToRequest', () {
    test('acepta una propuesta', () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/services/service-uuid-1/requests/request-uuid-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/requests/request-uuid-1',
          ),
          data: serviceRequestJson(status: 'ACCEPTED'),
        ),
      );

      // Act
      final result = await repository.respondToRequest(
        'service-uuid-1',
        'request-uuid-1',
        RequestStatus.accepted,
      );

      // Assert
      expect(result.status, RequestStatus.accepted);
    });

    test(
      'lanza ServiceConflictFailure cuando el servicio ya no está PENDING',
      () async {
        // Arrange
        when(
          () => dio.put<Map<String, dynamic>>(
            '/services/service-uuid-1/requests/request-uuid-1',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          conflictError('/services/service-uuid-1/requests/request-uuid-1'),
        );

        // Act & Assert
        await expectLater(
          repository.respondToRequest(
            'service-uuid-1',
            'request-uuid-1',
            RequestStatus.accepted,
          ),
          throwsA(isA<ServiceConflictFailure>()),
        );
      },
    );
  });

  group('startService', () {
    test('inicia el servicio asignado', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>('/services/service-uuid-1/start'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: '/services/service-uuid-1/start'),
          data: serviceJson(status: 'IN_PROGRESS'),
        ),
      );

      // Act
      final result = await repository.startService('service-uuid-1');

      // Assert
      expect(result.status, ServiceStatus.inProgress);
    });

    test(
      'lanza ServiceConflictFailure cuando el servicio ya no está ACCEPTED',
      () async {
        // Arrange
        when(
          () =>
              dio.post<Map<String, dynamic>>('/services/service-uuid-1/start'),
        ).thenThrow(conflictError('/services/service-uuid-1/start'));

        // Act & Assert
        await expectLater(
          repository.startService('service-uuid-1'),
          throwsA(isA<ServiceConflictFailure>()),
        );
      },
    );
  });

  group('completeService', () {
    test('completa el servicio en progreso', () async {
      // Arrange
      when(
        () =>
            dio.post<Map<String, dynamic>>('/services/service-uuid-1/complete'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/services/service-uuid-1/complete',
          ),
          data: serviceJson(status: 'COMPLETED'),
        ),
      );

      // Act
      final result = await repository.completeService('service-uuid-1');

      // Assert
      expect(result.status, ServiceStatus.completed);
    });

    test(
      'lanza ServiceConflictFailure cuando el servicio ya no está IN_PROGRESS',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>(
            '/services/service-uuid-1/complete',
          ),
        ).thenThrow(conflictError('/services/service-uuid-1/complete'));

        // Act & Assert
        await expectLater(
          repository.completeService('service-uuid-1'),
          throwsA(isA<ServiceConflictFailure>()),
        );
      },
    );

    test(
      'lanza ServiceServiceUnavailableFailure ante un 5xx',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>(
            '/services/service-uuid-1/complete',
          ),
        ).thenThrow(networkError('/services/service-uuid-1/complete'));

        // Act & Assert
        await expectLater(
          repository.completeService('service-uuid-1'),
          throwsA(isA<ServiceServiceUnavailableFailure>()),
        );
      },
    );
  });

  group('cancelService', () {
    test('cancela con el motivo provisto', () async {
      // Arrange
      when(
        () => dio.delete<Map<String, dynamic>>(
          '/services/service-uuid-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/service-uuid-1'),
          data: serviceJson(status: 'CANCELLED'),
        ),
      );

      // Act
      final result = await repository.cancelService(
        'service-uuid-1',
        'Ya no lo necesito',
      );

      // Assert
      expect(result.status, ServiceStatus.cancelled);
    });
  });
}
