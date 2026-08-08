import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/profile/data/profile_repository.dart';
import 'package:tekoapp_mobile/features/profile/models/profile_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ProfileRepository repository;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = ProfileRepository(ApiClient(dio: dio));
  });

  Response<Map<String, dynamic>> jsonResponse(
    String path,
    Map<String, dynamic> data,
  ) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  group('updateMe', () {
    test('manda solo los campos no nulos al body', () async {
      // Arrange
      when(
        () => dio.put<Map<String, dynamic>>(
          '/auth/me',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => jsonResponse('/auth/me', {}));

      // Act
      await repository.updateMe(firstName: 'Ana');

      // Assert
      final captured = verify(
        () => dio.put<Map<String, dynamic>>(
          '/auth/me',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured, {'firstName': 'Ana'});
    });

    test(
      'lanza ProfileValidationFailure cuando el backend responde 400',
      () async {
        // Arrange
        when(
          () => dio.put<Map<String, dynamic>>(
            '/auth/me',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/me'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/me'),
              statusCode: 400,
            ),
          ),
        );

        // Act & Assert
        await expectLater(
          repository.updateMe(phoneNumber: 'no-es-un-telefono'),
          throwsA(isA<ProfileValidationFailure>()),
        );
      },
    );

    test(
      'lanza ProfileServiceUnavailableFailure ante 5xx o sin conexión',
      () async {
        // Arrange
        when(
          () => dio.put<Map<String, dynamic>>(
            '/auth/me',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(requestOptions: RequestOptions(path: '/auth/me')),
        );

        // Act & Assert
        await expectLater(
          repository.updateMe(firstName: 'Ana'),
          throwsA(isA<ProfileServiceUnavailableFailure>()),
        );
      },
    );
  });

  group('uploadAvatar', () {
    test('devuelve la key cuando la subida es exitosa', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/uploads/avatar',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse('/uploads/avatar', {'key': 'abc123.jpg'}),
      );

      // Act
      final result = await repository.uploadAvatar(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
      );

      // Assert
      expect(result, 'abc123.jpg');
    });

    test(
      'lanza AvatarTooLargeFailure sin llegar a llamar al backend si supera el límite',
      () async {
        // Arrange
        final tooLarge = Uint8List(
          ProfileRepository.maxAvatarBytes + 1,
        );

        // Act & Assert
        await expectLater(
          repository.uploadAvatar(
            bytes: tooLarge,
            filename: 'foto.jpg',
            mimeType: 'image/jpeg',
          ),
          throwsA(isA<AvatarTooLargeFailure>()),
        );
        verifyNever(
          () => dio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        );
      },
    );

    test(
      'lanza AvatarUnsupportedTypeFailure sin llegar a llamar al backend',
      () async {
        // Act & Assert
        await expectLater(
          repository.uploadAvatar(
            bytes: Uint8List.fromList([1, 2, 3]),
            filename: 'documento.pdf',
            mimeType: 'application/pdf',
          ),
          throwsA(isA<AvatarUnsupportedTypeFailure>()),
        );
        verifyNever(
          () => dio.post<Map<String, dynamic>>(
            any(),
            data: any(named: 'data'),
          ),
        );
      },
    );

    test(
      'lanza AvatarUploadServiceFailure cuando el backend rechaza la subida',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>(
            '/uploads/avatar',
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(requestOptions: RequestOptions(path: '/uploads/avatar')),
        );

        // Act & Assert
        await expectLater(
          repository.uploadAvatar(
            bytes: Uint8List.fromList([1, 2, 3]),
            filename: 'foto.jpg',
            mimeType: 'image/jpeg',
          ),
          throwsA(isA<AvatarUploadServiceFailure>()),
        );
      },
    );
  });
}
