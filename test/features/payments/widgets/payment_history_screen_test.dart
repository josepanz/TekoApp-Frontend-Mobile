import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/payments/widgets/payment_detail_screen.dart';
import 'package:tekoapp_mobile/features/payments/widgets/payment_history_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  final router = GoRouter(
    initialLocation: '/pagos/historial',
    routes: [
      GoRoute(
        path: '/pagos/historial',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/pagos/historial/:id',
        builder: (context, state) =>
            PaymentDetailScreen(paymentId: state.pathParameters['id']!),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(ApiClient(dio: dio))],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _serviceJson({int userId = 1}) => {
      'id': 'svc-uuid-1',
      'userId': userId,
      'professionalId': 2,
      'categoryId': 3,
      'serviceTypeId': 4,
      'title': 'Reparación',
      'description': 'desc',
      'status': 'COMPLETED',
      'latitude': -25.2,
      'longitude': -57.5,
      'address': 'Av. España 1234',
      'isUrgent': false,
      'createdAt': '2026-08-08T10:00:00.000Z',
    };

Map<String, dynamic> _paymentJson({String id = 'pay-uuid-1'}) => {
      'id': id,
      'userId': 1,
      'professionalId': 2,
      'serviceId': 'svc-uuid-1',
      'amount': 100000.0,
      'currencyCode': 'PYG',
      'fee': 0.0,
      'tax': 0.0,
      'totalAmount': 100000.0,
      'status': 'COMPLETED',
      'paymentMethod': 'CREDIT_CARD',
      'paymentProvider': 'STRIPE',
      'transactionId': 'txn-1',
      'createdAt': '2026-08-08T10:00:00.000Z',
    };

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  testWidgets(
    'deriva el userId de mis servicios y lista los pagos (modo cliente)',
    (tester) async {
      // Arrange
      when(
        () => dio.get<List<dynamic>>(
          '/services/my-services',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/my-services'),
          data: [_serviceJson()],
        ),
      );
      when(
        () => dio.get<List<dynamic>>(
          '/payments',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments'),
          data: [_paymentJson()],
        ),
      );

      // Act
      await _pumpScreen(tester, dio);

      // Assert
      verify(
        () => dio.get<List<dynamic>>(
          '/payments',
          queryParameters: {'userId': 1},
        ),
      ).called(1);
      expect(find.text('Monto: Gs. 100000'), findsOneWidget);
    },
  );

  testWidgets(
    'no llama a /payments cuando el cliente todavía no tiene servicios propios',
    (tester) async {
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
      await _pumpScreen(tester, dio);

      // Assert
      expect(find.text('Todavía no tenés pagos'), findsOneWidget);
      verifyNever(
        () => dio.get<List<dynamic>>(
          '/payments',
          queryParameters: any(named: 'queryParameters'),
        ),
      );
    },
  );

  testWidgets('navega al detalle al tocar un pago', (tester) async {
    // Arrange
    when(
      () => dio.get<List<dynamic>>(
        '/services/my-services',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/my-services'),
        data: [_serviceJson()],
      ),
    );
    when(
      () => dio.get<List<dynamic>>(
        '/payments',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments'),
        data: [_paymentJson()],
      ),
    );
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
    await tester.tap(find.byKey(const Key('payment_item_pay-uuid-1')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(PaymentDetailScreen), findsOneWidget);
  });
}
