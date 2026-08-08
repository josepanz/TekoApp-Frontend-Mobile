import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_profile.dart';
import 'package:tekoapp_mobile/features/professional_profile/models/professional_status.dart';
import 'package:tekoapp_mobile/features/professional_profile/providers/my_professional_profile_provider.dart';
import 'package:tekoapp_mobile/features/services/providers/available_services_provider.dart';

class _MockDio extends Mock implements Dio {}

const _profile = ProfessionalProfile(
  id: 2,
  referenceId: 'prof-uuid-1',
  categoryId: 3,
  description: 'Plomero',
  hourlyRate: 50000,
  status: ProfessionalStatus.pending,
  isAvailable: false,
  isOnline: false,
);

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  test('filtra por la categoría de mi perfil profesional', () async {
    // Arrange
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
        myProfessionalProfileProvider.overrideWith((ref) async => _profile),
      ],
    );
    addTearDown(container.dispose);
    when(
      () => dio.get<Map<String, dynamic>>(
        '/services',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services'),
        data: {
          'data': <Map<String, dynamic>>[],
          'pagination': {
            'total': 0,
            'page': 1,
            'pageSize': 10,
            'totalPages': 0,
          },
        },
      ),
    );

    // Act
    final result = await container.read(availableServicesProvider.future);

    // Assert
    expect(result, isEmpty);
    final captured = verify(
      () => dio.get<Map<String, dynamic>>(
        '/services',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;
    expect(captured['categoryId'], 3);
    expect(captured['status'], 'PENDING');
  });

  test(
    'devuelve una lista vacía si todavía no hay perfil profesional (defensivo)',
    () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(dio: dio)),
          myProfessionalProfileProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final result = await container.read(availableServicesProvider.future);

      // Assert
      expect(result, isEmpty);
      verifyNever(
        () => dio.get<Map<String, dynamic>>(
          '/services',
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    },
  );
}
