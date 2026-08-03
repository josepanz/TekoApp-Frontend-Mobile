import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/envelope_interceptor.dart';

class _MockHandler extends Mock implements ResponseInterceptorHandler {}

void main() {
  late EnvelopeInterceptor interceptor;
  late _MockHandler handler;

  setUp(() {
    interceptor = EnvelopeInterceptor();
    handler = _MockHandler();
  });

  Response<dynamic> buildResponse(dynamic data) {
    return Response(requestOptions: RequestOptions(path: '/test'), data: data);
  }

  test('desenvuelve el campo data cuando el backend responde con el envelope estándar', () {
    // Arrange
    final response = buildResponse({
      'success': true,
      'data': {'id': 1, 'name': 'Plomería'},
      'message': 'Operación exitosa',
    });

    // Act
    interceptor.onResponse(response, handler);

    // Assert
    expect(response.data, {'id': 1, 'name': 'Plomería'});
    verify(() => handler.next(response)).called(1);
  });

  test('deja la respuesta intacta cuando no viene envuelta (ej. un mock de test)', () {
    // Arrange
    final response = buildResponse({'id': 1, 'name': 'Plomería'});

    // Act
    interceptor.onResponse(response, handler);

    // Assert
    expect(response.data, {'id': 1, 'name': 'Plomería'});
    verify(() => handler.next(response)).called(1);
  });
}
