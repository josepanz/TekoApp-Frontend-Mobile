import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/professional_onboarding_controller_provider.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ProviderContainer container;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
    );
  });

  tearDown(() => container.dispose());

  test('activa el perfil y queda en estado exitoso', () async {
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
    await container
        .read(professionalOnboardingControllerProvider.notifier)
        .submit(
          categoryId: 3,
          description: 'Plomero',
          hourlyRate: 50000,
        );

    // Assert
    final state = container.read(professionalOnboardingControllerProvider);
    expect(state.hasError, isFalse);
  });

  test('deja un error de validación cuando el backend responde 400', () async {
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

    // Act
    await container
        .read(professionalOnboardingControllerProvider.notifier)
        .submit(
          categoryId: 3,
          description: 'Plomero',
          hourlyRate: 50000,
        );

    // Assert
    final state = container.read(professionalOnboardingControllerProvider);
    expect(state.hasError, isTrue);
  });
}
