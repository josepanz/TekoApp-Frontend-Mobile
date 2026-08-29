import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/api_client/api_client.dart';
import 'package:tekoapp_mobile/core/api_client/api_client_provider.dart';
import 'package:tekoapp_mobile/features/legal_consents/models/ai_disclosure_entity_type.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';
import 'package:tekoapp_mobile/shared/widgets/ai_disclosure_badge.dart';

class _MockDio extends Mock implements Dio {}

Future<void> _pumpBadge(WidgetTester tester, _MockDio dio) async {
  await tester.pumpWidget(
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
        home: Scaffold(
          body: AiDisclosureBadge(
            entityType: AiDisclosureEntityType.serviceDescription,
            entityReferenceId: 'svc-1',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockDio dio;

  setUp(() {
    dio = _MockDio();
    when(() => dio.interceptors).thenReturn(Interceptors());
  });

  testWidgets('no muestra nada cuando el contenido no tiene disclosure', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>?>(
        '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
        ),
        data: null,
      ),
    );

    // Act
    await _pumpBadge(tester, dio);

    // Assert
    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });

  testWidgets('muestra el ícono y el texto cuando existe un disclosure', (
    tester,
  ) async {
    // Arrange
    when(
      () => dio.get<Map<String, dynamic>?>(
        '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(
          path: '/ai-disclosures/SERVICE_DESCRIPTION/svc-1',
        ),
        data: {
          'referenceId': 'ai-1',
          'entityType': 'SERVICE_DESCRIPTION',
          'entityReferenceId': 'svc-1',
          'source': 'USER_DECLARED_AI',
          'aiProvider': null,
          'declaredByUserId': 5,
          'note': null,
          'createdAt': '2026-08-25T10:00:00.000Z',
        },
      ),
    );

    // Act
    await _pumpBadge(tester, dio);

    // Assert
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    expect(find.text('Asistido por IA'), findsOneWidget);
  });
}
