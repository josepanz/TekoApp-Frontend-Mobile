import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/promotions/data/promotions_repository.dart';
import 'package:tekoapp_mobile/features/promotions/models/promotion_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late PromotionsRepository repository;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = PromotionsRepository(ApiClient(dio: dio));
  });

  Response<Map<String, dynamic>> okResponse(
    String path,
    Map<String, dynamic> data,
  ) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  group('validate', () {
    test('mapea una promoción válida con su descuento', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/promotions/validate',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => okResponse('/promotions/validate', {
          'isValid': true,
          'discountAmount': 30000,
          'promotion': {'code': 'PROMO2025', 'name': 'Descuento de verano'},
        }),
      );

      // Act
      final result = await repository.validate(
        code: 'PROMO2025',
        serviceAmount: 150000,
      );

      // Assert
      expect(result.isValid, isTrue);
      expect(result.discountAmount, 30000.0);
      expect(result.promotion?.name, 'Descuento de verano');
    });

    test(
        'un código inválido/vencido llega como 200 isValid=false, no como error',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/promotions/validate',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => okResponse('/promotions/validate', {
          'isValid': false,
          'discountAmount': 0,
          'message': 'Código de promoción inválido',
        }),
      );

      // Act
      final result = await repository.validate(
        code: 'NOEXISTE',
        serviceAmount: 150000,
      );

      // Assert
      expect(result.isValid, isFalse);
      expect(result.message, 'Código de promoción inválido');
    });

    test('clasifica un 5xx como servicio no disponible', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/promotions/validate',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/promotions/validate'),
          response: Response(
            requestOptions: RequestOptions(path: '/promotions/validate'),
            statusCode: 503,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.validate(code: 'PROMO2025', serviceAmount: 150000),
        throwsA(isA<PromotionServiceUnavailableFailure>()),
      );
    });
  });

  group('apply', () {
    test('aplica el descuento y retorna el finalAmount', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/promotions/apply',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => okResponse('/promotions/apply', {
          'success': true,
          'discountAmount': 30000,
          'finalAmount': 120000,
          'promotion': {'code': 'PROMO2025', 'name': 'Descuento de verano'},
        }),
      );

      // Act
      final result = await repository.apply(
        code: 'PROMO2025',
        serviceAmount: 150000,
        serviceId: 'svc-uuid-1',
      );

      // Assert
      expect(result.success, isTrue);
      expect(result.finalAmount, 120000.0);
      final sentData = verify(
        () => dio.post<Map<String, dynamic>>(
          '/promotions/apply',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(sentData['promotionCode'], 'PROMO2025');
      expect(sentData['serviceId'], 'svc-uuid-1');
    });

    test('un cupo ya agotado llega como success=false, no como error',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/promotions/apply',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => okResponse('/promotions/apply', {
          'success': false,
          'discountAmount': 0,
          'finalAmount': 150000,
          'message': 'Se alcanzó el límite de usos de la promoción',
        }),
      );

      // Act
      final result = await repository.apply(
        code: 'PROMO2025',
        serviceAmount: 150000,
      );

      // Assert
      expect(result.success, isFalse);
      expect(result.finalAmount, 150000.0);
    });
  });
}
