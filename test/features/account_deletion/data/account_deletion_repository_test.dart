import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/account_deletion/data/account_deletion_repository.dart';
import 'package:tekoapp_mobile/features/account_deletion/models/account_deletion_failure.dart';
import 'package:tekoapp_mobile/features/account_deletion/models/deletion_blocker.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late AccountDeletionRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = AccountDeletionRepository(ApiClient(dio: dio));
  });

  DioException errorResponse(
    String path, {
    required int statusCode,
    String? errorCode,
    Map<String, dynamic>? details,
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
            'message': 'x',
            if (errorCode != null) 'errorCode': errorCode,
            if (details != null) 'details': details,
          },
        },
      ),
    );
  }

  group('requestDeletion', () {
    test('completa sin error cuando el backend acepta la solicitud', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>('/auth/me/deletion-request'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/auth/me/deletion-request'),
          data: {
            'status': 'PENDING_DELETION',
            'deletionRequestedAt': '2026-09-11T10:00:00.000Z',
            'deletionScheduledAt': '2026-09-25T10:00:00.000Z',
          },
        ),
      );

      // Act & Assert
      await expectLater(repository.requestDeletion(), completes);
    });

    test(
      'lanza AccountDeletionBlockedFailure con los bloqueantes mapeados en 409 DELETION_BLOCKED',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>('/auth/me/deletion-request'),
        ).thenThrow(
          errorResponse(
            '/auth/me/deletion-request',
            statusCode: 409,
            errorCode: 'DELETION_BLOCKED',
            details: {
              'blockers': [
                {'type': 'ACTIVE_SERVICE', 'count': 1},
                {'type': 'PENDING_PAYMENT', 'count': 2},
              ],
            },
          ),
        );

        // Act & Assert
        try {
          await repository.requestDeletion();
          fail('debía lanzar AccountDeletionBlockedFailure');
        } on AccountDeletionBlockedFailure catch (failure) {
          expect(failure.blockers, hasLength(2));
          expect(failure.blockers[0].type, DeletionBlockerType.activeService);
          expect(failure.blockers[0].count, 1);
          expect(failure.blockers[1].type, DeletionBlockerType.pendingPayment);
          expect(failure.blockers[1].count, 2);
        }
      },
    );

    test(
      'lanza AccountDeletionAlreadyRequestedFailure en 409 DELETION_ALREADY_REQUESTED',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>('/auth/me/deletion-request'),
        ).thenThrow(
          errorResponse(
            '/auth/me/deletion-request',
            statusCode: 409,
            errorCode: 'DELETION_ALREADY_REQUESTED',
          ),
        );

        // Act & Assert
        await expectLater(
          repository.requestDeletion(),
          throwsA(isA<AccountDeletionAlreadyRequestedFailure>()),
        );
      },
    );

    test(
      'lanza AccountDeletionNoConnectionFailure sin respuesta del servidor',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>('/auth/me/deletion-request'),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/me/deletion-request'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        await expectLater(
          repository.requestDeletion(),
          throwsA(isA<AccountDeletionNoConnectionFailure>()),
        );
      },
    );
  });

  group('cancelDeletion', () {
    test('completa sin error cuando el backend cancela la solicitud', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/me/deletion-request/cancel',
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/auth/me/deletion-request/cancel',
          ),
          data: {'status': 'ACTIVE'},
        ),
      );

      // Act & Assert
      await expectLater(repository.cancelDeletion(), completes);
    });

    test(
      'lanza AccountDeletionNotRequestedFailure en 400 DELETION_NOT_REQUESTED',
      () async {
        // Arrange
        when(
          () => dio.post<Map<String, dynamic>>(
            '/auth/me/deletion-request/cancel',
          ),
        ).thenThrow(
          errorResponse(
            '/auth/me/deletion-request/cancel',
            statusCode: 400,
            errorCode: 'DELETION_NOT_REQUESTED',
          ),
        );

        // Act & Assert
        await expectLater(
          repository.cancelDeletion(),
          throwsA(isA<AccountDeletionNotRequestedFailure>()),
        );
      },
    );
  });
}
