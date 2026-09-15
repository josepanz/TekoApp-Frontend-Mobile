import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/payments/widgets/pay_service_screen.dart';
import 'package:tekoapp_mobile/features/payments/widgets/payment_history_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpScreen(WidgetTester tester, _MockDio dio) async {
  final router = GoRouter(
    initialLocation: '/pagos/pagar/svc-uuid-1',
    routes: [
      GoRoute(
        path: '/pagos/pagar/:serviceId',
        builder: (context, state) =>
            PayServiceScreen(serviceId: state.pathParameters['serviceId']!),
      ),
      GoRoute(
        path: '/pagos/historial',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/pagos/metodos/nuevo',
        builder: (context, state) => const Scaffold(body: Text('alta')),
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

Map<String, dynamic> _serviceJson({double? finalAmount = 100000}) => {
      'id': 1,
      'referenceId': 'svc-uuid-1',
      'userId': 1,
      'professionalId': 2,
      'categoryId': 3,
      'serviceTypeId': 4,
      'title': 'Reparación',
      'description': 'desc',
      'status': 'COMPLETED',
      'latitude': -25.2,
      'longitude': -57.5,
      'address': 'Av. España 1234',
      'images': <String>[],
      'isUrgent': false,
      'createdAt': '2026-08-08T10:00:00.000Z',
      if (finalAmount != null) 'finalAmount': finalAmount,
      'users': {
        'id': 10,
        'referenceId': 'client-uuid-1',
        'firstName': 'María',
        'lastName': 'López',
        'email': 'maria@example.com',
      },
      'professional': {
        'id': 2,
        'referenceId': 'prof-uuid-1',
        'user': {'firstName': 'Ana', 'lastName': 'Pérez'},
      },
    };

Map<String, dynamic> _methodJson({
  int id = 1,
  String referenceId = 'pm-uuid-1',
  String name = 'Visa terminada en 4242',
  String? expiresAt,
}) =>
    {
      'id': id,
      'referenceId': referenceId,
      'userId': 1,
      'name': name,
      'type': 'CREDIT_CARD',
      'provider': 'STRIPE',
      'isDefault': true,
      'isActive': true,
      'details': <String, dynamic>{},
      'externalId': null,
      if (expiresAt != null) 'expiresAt': expiresAt,
      'createdAt': '2026-08-08T10:00:00.000Z',
      'updatedAt': '2026-08-08T10:00:00.000Z',
    };

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  testWidgets(
      'muestra el monto no editable y ofrece agregar un método si no hay ninguno',
      (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/services/svc-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/svc-uuid-1'),
        data: _serviceJson(),
      ),
    );
    when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: [],
      ),
    );

    // Act
    await _pumpScreen(tester, dio);

    // Assert
    expect(find.text('Monto: Gs. 100000'), findsOneWidget);
    expect(
      find.text('No tenés métodos de pago guardados'),
      findsOneWidget,
    );
  });

  testWidgets('valida un código de promoción y muestra el descuento', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>>('/services/svc-uuid-1'),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/services/svc-uuid-1'),
        data: _serviceJson(),
      ),
    );
    when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/payments/methods'),
        data: [_methodJson()],
      ),
    );
    when(
      () => dio.post<Map<String, dynamic>>(
        '/promotions/validate',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: '/promotions/validate'),
        data: {'isValid': true, 'discountAmount': 20000},
      ),
    );

    // Act
    await _pumpScreen(tester, dio);
    await tester.enterText(
      find.byKey(const Key('pay_service_promo_code_field')),
      'PROMO2025',
    );
    await tester
        .tap(find.byKey(const Key('pay_service_validate_promo_button')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Descuento: Gs. 20000'), findsOneWidget);
  });

  testWidgets(
    'confirma el pago sin promoción y navega al historial',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/svc-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/svc-uuid-1'),
          data: _serviceJson(),
        ),
      );
      when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/methods'),
          data: [_methodJson()],
        ),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments'),
          data: {
            'id': 1,
            'referenceId': 'pay-uuid-1',
            'userId': 1,
            'professionalId': 2,
            'serviceId': 'svc-uuid-1',
            'amount': 100000.0,
            'currencyCode': 'PYG',
            'fee': 0.0,
            'tax': 0.0,
            'totalAmount': 100000.0,
            'status': 'PENDING',
            'paymentMethod': 'CREDIT_CARD',
            'paymentProvider': 'STRIPE',
            'transactionId': 'txn-1',
            'platformFee': 0.0,
            'isRecurring': false,
            'createdAt': '2026-08-08T10:00:00.000Z',
          },
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
          data: [],
        ),
      );
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
      await tester.tap(find.byKey(const Key('pay_service_method_field')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.text('Visa terminada en 4242 · Tarjeta de crédito').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay_service_confirm_button')));
      await tester.pumpAndSettle();

      // Assert
      final sentData = verify(
        () => dio.post<Map<String, dynamic>>(
          '/payments',
          data: captureAny(named: 'data'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(sentData['professionalId'], 'prof-uuid-1');
      expect(sentData['amount'], 100000.0);
      expect(find.byType(PayServiceScreen), findsNothing);
      expect(find.byType(PaymentHistoryScreen), findsOneWidget);
    },
  );

  testWidgets(
    'muestra el mensaje EXACTO del backend cuando ya existe un pago para el servicio',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/svc-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/svc-uuid-1'),
          data: _serviceJson(),
        ),
      );
      when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/methods'),
          data: [_methodJson()],
        ),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/payments'),
          response: Response(
            requestOptions: RequestOptions(path: '/payments'),
            statusCode: 400,
            data: {
              'success': false,
              'error': {
                'code': 400,
                'message': 'Ya existe un pago para este servicio',
              },
            },
          ),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.tap(find.byKey(const Key('pay_service_method_field')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.text('Visa terminada en 4242 · Tarjeta de crédito').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay_service_confirm_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Ya existe un pago para este servicio'), findsOneWidget);
      expect(find.byType(PayServiceScreen), findsOneWidget);
    },
  );

  testWidgets(
    'deshabilita en el selector un método de pago vencido y no permite elegirlo',
    (tester) async {
      // Arrange
      when(
        () => dio.get<Map<String, dynamic>>('/services/svc-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/svc-uuid-1'),
          data: _serviceJson(),
        ),
      );
      when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/methods'),
          data: [_methodJson(expiresAt: '2020-01-01T00:00:00.000Z')],
        ),
      );

      // Act
      await _pumpScreen(tester, dio);

      // Assert: la aclaración de "vencido" está visible y el botón de confirmar
      // queda deshabilitado porque no se puede elegir el único método (vencido).
      expect(
        find.text(
          'Los métodos vencidos aparecen deshabilitados — no se pueden usar para pagar.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('pay_service_method_field')));
      await tester.pumpAndSettle();
      expect(
        find.text('Visa terminada en 4242 · Tarjeta de crédito · Vencido'),
        findsWidgets,
      );
      // Cierra el dropdown sin poder elegir la única opción (deshabilitada).
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final confirmButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: find.byKey(const Key('pay_service_confirm_button')),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(confirmButton.onPressed, isNull);
    },
  );

  testWidgets(
    'muestra un mensaje específico cuando el backend rechaza el pago por PAYMENT_METHOD_EXPIRED',
    (tester) async {
      // Arrange: el método NO está vencido según la UI (venció recién entre que se pintó la
      // pantalla y se confirmó el pago) — el backend es la fuente de verdad final.
      when(
        () => dio.get<Map<String, dynamic>>('/services/svc-uuid-1'),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/services/svc-uuid-1'),
          data: _serviceJson(),
        ),
      );
      when(() => dio.get<List<dynamic>>('/payments/methods')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/payments/methods'),
          data: [_methodJson()],
        ),
      );
      when(
        () => dio.post<Map<String, dynamic>>(
          '/payments',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/payments'),
          response: Response(
            requestOptions: RequestOptions(path: '/payments'),
            statusCode: 400,
            data: {
              'success': false,
              'error': {
                'code': 400,
                'message': 'El medio de pago seleccionado está vencido',
                'errorCode': 'PAYMENT_METHOD_EXPIRED',
              },
            },
          ),
        ),
      );

      // Act
      await _pumpScreen(tester, dio);
      await tester.tap(find.byKey(const Key('pay_service_method_field')));
      await tester.pumpAndSettle();
      await tester
          .tap(find.text('Visa terminada en 4242 · Tarjeta de crédito').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay_service_confirm_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('El medio de pago seleccionado está vencido'),
        findsOneWidget,
      );
      expect(find.byType(PayServiceScreen), findsOneWidget);
    },
  );
}
