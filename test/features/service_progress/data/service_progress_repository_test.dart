import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/service_progress/data/service_progress_repository.dart';
import 'package:tekoapp_mobile/features/service_progress/models/service_progress_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ServiceProgressRepository repository;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = ServiceProgressRepository(ApiClient(dio: dio));
  });

  Response<Map<String, dynamic>> jsonResponse(
    String path,
    Map<String, dynamic> data,
  ) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  group('uploadImage', () {
    test('devuelve la key cuando la subida es exitosa', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/uploads/image',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse('/uploads/image', {'key': 'foto-1.jpg'}),
      );

      // Act
      final result = await repository.uploadImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
      );

      // Assert
      expect(result, 'foto-1.jpg');
    });
  });

  group('createEntry', () {
    test('manda solo note e images no vacíos', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services/svc-1/progress',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse('/services/svc-1/progress', {
          'referenceId': 'entry-1',
          'note': 'Avance',
          'images': ['foto-1.jpg'],
          'entryOrder': 1,
          'createdAt': '2026-08-27T10:00:00.000Z',
          'editWindowExpired': false,
        }),
      );

      // Act
      final result = await repository.createEntry(
        serviceId: 'svc-1',
        note: 'Avance',
        images: ['foto-1.jpg'],
      );

      // Assert
      expect(result.referenceId, 'entry-1');
      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/services/svc-1/progress',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured, {
        'note': 'Avance',
        'images': ['foto-1.jpg'],
      });
    });

    test('lanza ServiceProgressConflictFailure cuando el backend responde 409',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services/svc-1/progress',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/services/svc-1/progress'),
          response: Response(
            requestOptions: RequestOptions(path: '/services/svc-1/progress'),
            statusCode: 409,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.createEntry(serviceId: 'svc-1', note: 'x'),
        throwsA(isA<ServiceProgressConflictFailure>()),
      );
    });

    test('lanza ServiceProgressForbiddenFailure cuando el backend responde 403',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/services/svc-1/progress',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/services/svc-1/progress'),
          response: Response(
            requestOptions: RequestOptions(path: '/services/svc-1/progress'),
            statusCode: 403,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.createEntry(serviceId: 'svc-1', note: 'x'),
        throwsA(isA<ServiceProgressForbiddenFailure>()),
      );
    });
  });

  group('listByService', () {
    test('parsea la lista ordenada de entradas', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/svc-1/progress'),
      ).thenAnswer(
        (_) async => jsonResponse('/services/svc-1/progress', {
          'data': [
            {
              'referenceId': 'entry-1',
              'note': null,
              'images': <String>[],
              'entryOrder': 1,
              'createdAt': '2026-08-27T10:00:00.000Z',
              'editWindowExpired': true,
            },
          ],
        }),
      );

      // Act
      final result = await repository.listByService('svc-1');

      // Assert
      expect(result, hasLength(1));
      expect(result.single.editWindowExpired, isTrue);
    });
  });

  group('deleteEntry', () {
    test(
        'lanza ServiceProgressConflictFailure cuando venció la ventana de corrección',
        () async {
      // Arrange
      when(
        () => dio.delete<void>('/services/svc-1/progress/entry-1'),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/services/svc-1/progress/entry-1',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/services/svc-1/progress/entry-1',
            ),
            statusCode: 409,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.deleteEntry(serviceId: 'svc-1', entryId: 'entry-1'),
        throwsA(isA<ServiceProgressConflictFailure>()),
      );
    });
  });

  group('resolvePhotoUrl', () {
    test('pasa la key como query param y devuelve la url', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>(
          '/uploads/presigned-url',
          queryParameters: {'key': 'foto-1.jpg'},
        ),
      ).thenAnswer(
        (_) async => jsonResponse(
          '/uploads/presigned-url',
          {'url': 'https://s3/foto-1.jpg?sig=abc'},
        ),
      );

      // Act
      final result = await repository.resolvePhotoUrl('foto-1.jpg');

      // Assert
      expect(result, 'https://s3/foto-1.jpg?sig=abc');
    });
  });
}
