import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/data/professional_portfolio_repository.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/models/portfolio_failure.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio dio;
  late ProfessionalPortfolioRepository repository;

  setUpAll(() {
    registerFallbackValue(FormData());
  });

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
    repository = ProfessionalPortfolioRepository(ApiClient(dio: dio));
  });

  Response<Map<String, dynamic>> jsonResponse(
    String path,
    Map<String, dynamic> data,
  ) {
    return Response(requestOptions: RequestOptions(path: path), data: data);
  }

  Map<String, dynamic> itemJson({String status = 'PENDING'}) => {
        'referenceId': 'portfolio-1',
        'fileKey': 'abc.jpg',
        'caption': 'Instalación de cañerías',
        'sortOrder': 0,
        'isVisible': true,
        'status': status,
        'createdAt': '2026-09-01T10:00:00.000Z',
      };

  group('myPortfolio', () {
    test('parsea la lista de fotos propias', () async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/professionals/me/portfolio'),
      ).thenAnswer(
        (_) async => jsonResponse('/professionals/me/portfolio', {
          'data': [itemJson()],
        }),
      );

      // Act
      final result = await repository.myPortfolio();

      // Assert
      expect(result, hasLength(1));
      expect(result.single.caption, 'Instalación de cañerías');
    });
  });

  group('upload', () {
    test('manda el archivo y el caption en un solo multipart', () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/professionals/me/portfolio',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async =>
            jsonResponse('/professionals/me/portfolio', itemJson()),
      );

      // Act
      final result = await repository.upload(
        bytes: Uint8List.fromList([1, 2, 3]),
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
        caption: 'Instalación de cañerías',
      );

      // Assert
      expect(result.referenceId, 'portfolio-1');
      final captured = verify(
        () => dio.post<Map<String, dynamic>>(
          '/professionals/me/portfolio',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as FormData;
      expect(captured.fields.map((e) => e.key), contains('caption'));
      expect(captured.files.single.key, 'file');
    });

    test('lanza PortfolioValidationFailure cuando el backend responde 400',
        () async {
      // Arrange
      when(
        () => dio.post<Map<String, dynamic>>(
          '/professionals/me/portfolio',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/professionals/me/portfolio'),
          response: Response(
            requestOptions:
                RequestOptions(path: '/professionals/me/portfolio'),
            statusCode: 400,
          ),
        ),
      );

      // Act & Assert
      await expectLater(
        repository.upload(
          bytes: Uint8List.fromList([1]),
          filename: 'foto.jpg',
          mimeType: 'image/jpeg',
        ),
        throwsA(isA<PortfolioValidationFailure>()),
      );
    });
  });

  group('update', () {
    test('manda solo los campos provistos', () async {
      // Arrange
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/professionals/me/portfolio/portfolio-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => jsonResponse(
          '/professionals/me/portfolio/portfolio-1',
          itemJson()..['isVisible'] = false,
        ),
      );

      // Act
      final result = await repository.update('portfolio-1', isVisible: false);

      // Assert
      expect(result.isVisible, isFalse);
      final captured = verify(
        () => dio.patch<Map<String, dynamic>>(
          '/professionals/me/portfolio/portfolio-1',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured, {'isVisible': false});
    });
  });

  group('delete', () {
    test('llama al endpoint de borrado', () async {
      // Arrange
      when(
        () => dio.delete<void>('/professionals/me/portfolio/portfolio-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '/professionals/me/portfolio/portfolio-1',
          ),
        ),
      );

      // Act
      await repository.delete('portfolio-1');

      // Assert
      verify(
        () => dio.delete<void>('/professionals/me/portfolio/portfolio-1'),
      ).called(1);
    });
  });
}
