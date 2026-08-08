import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/services/providers/my_professional_services_provider.dart';

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

  test('pide el rol profesional y mapea el listado', () async {
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
    final result = await container.read(
      myProfessionalServicesProvider.future,
    );

    // Assert
    expect(result, isEmpty);
    final captured = verify(
      () => dio.get<List<dynamic>>(
        '/services/my-services',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single as Map<String, dynamic>;
    expect(captured['role'], 'professional');
  });
}
