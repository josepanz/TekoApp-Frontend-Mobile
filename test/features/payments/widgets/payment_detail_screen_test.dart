import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/payments/widgets/payment_detail_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaymentDetailScreen(paymentId: 'pay-uuid-1'),
      ),
    ),
  );
}

Map<String, dynamic> _paymentJson({
  String status = 'COMPLETED',
  double totalAmount = 100000,
  Map<String, dynamic>? refundDetails,
  Map<String, dynamic>? tip,
}) =>
    {
      'id': 1,
      'referenceId': 'pay-uuid-1',
      'userId': 1,
      'professionalId': 2,
      'serviceId': 'svc-uuid-1',
      'amount': totalAmount,
      'currencyCode': 'PYG',
      'fee': 0.0,
      'tax': 0.0,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': 'CREDIT_CARD',
      'paymentProvider': 'STRIPE',
      'transactionId': 'txn-1',
      'createdAt': '2026-08-08T10:00:00.000Z',
      if (refundDetails != null) 'refundDetails': refundDetails,
      'tip': tip,
    };

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  testWidgets('muestra el monto y el estado del pago', (tester) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/pay-uuid-1'),
        data: _paymentJson(),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Monto: Gs. 100000'), findsOneWidget);
    expect(find.text('Completado'), findsOneWidget);
    expect(find.byKey(const Key('payment_refund_button')), findsOneWidget);
  });

  testWidgets('no ofrece reembolsar un pago pendiente', (tester) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/pay-uuid-1'),
        data: _paymentJson(status: 'PENDING'),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(const Key('payment_refund_button')), findsNothing);
  });

  testWidgets(
    'permite un segundo reembolso parcial sobre un pago ya PARTIAL_REFUNDED',
    (tester) async {
      // Arrange — el pago ya tiene un reembolso parcial previo de 40000 sobre 100000
      when(
        () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/pay-uuid-1'),
          data: _paymentJson(
            status: 'PARTIAL_REFUNDED',
            refundDetails: {'refundedAmount': 40000},
          ),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();

      // Assert — el botón sigue disponible porque queda 60000 por reembolsar
      expect(find.byKey(const Key('payment_refund_button')), findsOneWidget);
      expect(
        find.text('Disponible para reembolsar: Gs. 60000'),
        findsOneWidget,
      );
    },
  );

  testWidgets('procesa el reembolso y muestra el mensaje de éxito', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/pay-uuid-1'),
        data: _paymentJson(),
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>(
        '/payments/pay-uuid-1/refund',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/pay-uuid-1/refund'),
        data: _paymentJson(
          status: 'PARTIAL_REFUNDED',
          refundDetails: {'refundedAmount': 50000},
        ),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('payment_refund_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('refund_amount_field')),
      '50000',
    );
    await tester.tap(find.byKey(const Key('refund_dialog_submit_button')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Reembolso procesado'), findsOneWidget);
  });

  testWidgets(
    'muestra el mensaje EXACTO del backend cuando el monto excede lo disponible',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/pay-uuid-1'),
          data: _paymentJson(),
        ),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments/pay-uuid-1/refund',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(
            path: '/payments/pay-uuid-1/refund',
          ),
          response: Response(
            requestOptions: RequestOptions(
              path: '/payments/pay-uuid-1/refund',
            ),
            statusCode: 400,
            data: {
              'success': false,
              'error': {
                'code': 400,
                'message': 'El monto del reembolso excede el monto disponible',
              },
            },
          ),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payment_refund_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('refund_amount_field')),
        '100000',
      );
      await tester.tap(find.byKey(const Key('refund_dialog_submit_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('El monto del reembolso excede el monto disponible'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'muestra el botón de dejar propina cuando el pago está completado y sin propina',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/pay-uuid-1'),
          data: _paymentJson(),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('payment_tip_button')), findsOneWidget);
    },
  );

  testWidgets('muestra la propina ya dejada en vez del botón', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/pay-uuid-1'),
        data: _paymentJson(
          tip: {
            'referenceId': 'tip-uuid-1',
            'mode': 'PERCENTAGE',
            'percentage': 10,
            'amount': 10000,
            'currencyCode': 'PYG',
            'createdAt': '2026-08-08T10:00:00.000Z',
          },
        ),
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Propina: Gs. 10000'), findsOneWidget);
    expect(find.byKey(const Key('payment_tip_button')), findsNothing);
  });

  testWidgets(
    'envía una propina por porcentaje y muestra el mensaje de éxito',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/payments/pay-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/pay-uuid-1'),
          data: _paymentJson(),
        ),
      );
      when(() => dio.get<Map<String, dynamic>>('/tips/config')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/tips/config'),
          data: {
            'isEnabled': true,
            'isMandatory': false,
            'suggestedPercentages': [10, 15, 20],
            'allowFreeAmount': true,
          },
        ),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments/pay-uuid-1/tip',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/pay-uuid-1/tip'),
          data: {
            'referenceId': 'tip-uuid-1',
            'mode': 'PERCENTAGE',
            'percentage': 10,
            'amount': 10000,
            'currencyCode': 'PYG',
            'createdAt': '2026-08-08T10:00:00.000Z',
          },
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payment_tip_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tip_percentage_chip_10')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tip_dialog_submit_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('¡Gracias! Propina enviada'), findsOneWidget);
      final sentData = verify(
        () => dio.post<Map<String, dynamic>>(
          '/payments/pay-uuid-1/tip',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(sentData['mode'], 'PERCENTAGE');
      expect(sentData['percentage'], 10);
    },
  );
}
