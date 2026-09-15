import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/features/account_deletion/data/account_deletion_repository.dart';
import 'package:tekoapp_mobile/features/account_deletion/models/account_deletion_failure.dart';
import 'package:tekoapp_mobile/features/account_deletion/models/deletion_blocker.dart';
import 'package:tekoapp_mobile/features/account_deletion/providers/account_deletion_repository_provider.dart';
import 'package:tekoapp_mobile/features/account_deletion/widgets/account_deletion_screen.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockAccountDeletionRepository extends Mock
    implements AccountDeletionRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this._fixed);
  final SessionState _fixed;

  @override
  SessionState build() => _fixed;
}

const _user = UserSummary(
  referenceId: 'ref-1',
  email: 'a@b.com',
  firstName: 'Ana',
  lastName: 'Pérez',
);

Future<GoRouter> _pumpScreen(
  WidgetTester tester, {
  required _MockAccountDeletionRepository repository,
  required _MockAuthRepository authRepository,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('home')),
      ),
      GoRoute(
        path: '/eliminar-cuenta',
        builder: (context, state) => const AccountDeletionScreen(),
      ),
      GoRoute(
        path: '/mis-servicios',
        builder: (context, state) => const Scaffold(body: Text('servicios')),
      ),
      GoRoute(
        path: '/pagos/historial',
        builder: (context, state) => const Scaffold(body: Text('pagos')),
      ),
      GoRoute(
        path: '/contratos',
        builder: (context, state) => const Scaffold(body: Text('contratos')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(
          () => _FixedSessionNotifier(const SessionAuthenticated(_user)),
        ),
        accountDeletionRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
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
  router.push('/eliminar-cuenta');
  await tester.pumpAndSettle();
  return router;
}

void main() {
  late _MockAccountDeletionRepository repository;
  late _MockAuthRepository authRepository;

  setUp(() {
    repository = _MockAccountDeletionRepository();
    authRepository = _MockAuthRepository();
  });

  testWidgets(
    'el botón de confirmar arranca deshabilitado hasta marcar el checkbox',
    (tester) async {
      // Arrange & Act
      await _pumpScreen(
        tester,
        repository: repository,
        authRepository: authRepository,
      );
      final buttonFinder = find.byKey(
        const Key('account_deletion_confirm_button'),
      );

      // Assert: deshabilitado (TekoButton envuelve un ElevatedButton, onPressed null)
      final button = tester.widget<ElevatedButton>(
        find.descendant(
          of: buttonFinder,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(button.onPressed, isNull);

      // Act: marcar el checkbox
      await tester.tap(
        find.byKey(const Key('account_deletion_understood_checkbox')),
      );
      await tester.pumpAndSettle();

      // Assert: habilitado
      final enabledButton = tester.widget<ElevatedButton>(
        find.descendant(
          of: buttonFinder,
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(enabledButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'confirmar exitosamente refresca la sesión y muestra la pantalla de éxito',
    (tester) async {
      // Arrange
      when(() => repository.requestDeletion()).thenAnswer((_) async {});
      when(() => authRepository.fetchScope()).thenAnswer(
        (_) async => UserSummary(
          referenceId: _user.referenceId,
          email: _user.email,
          firstName: _user.firstName,
          lastName: _user.lastName,
          deletionScheduledAt: DateTime(2026, 9, 25),
        ),
      );
      await _pumpScreen(
        tester,
        repository: repository,
        authRepository: authRepository,
      );

      // Act
      await tester.tap(
        find.byKey(const Key('account_deletion_understood_checkbox')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('account_deletion_confirm_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.requestDeletion()).called(1);
      expect(
        find.byKey(const Key('account_deletion_success_back_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un 409 DELETION_BLOCKED muestra cada bloqueante con su acción, no un error genérico',
    (tester) async {
      // Arrange
      when(() => repository.requestDeletion()).thenThrow(
        const AccountDeletionBlockedFailure([
          DeletionBlocker(type: DeletionBlockerType.activeService, count: 1),
          DeletionBlocker(type: DeletionBlockerType.pendingPayment, count: 2),
        ]),
      );
      await _pumpScreen(
        tester,
        repository: repository,
        authRepository: authRepository,
      );

      // Act
      await tester.tap(
        find.byKey(const Key('account_deletion_understood_checkbox')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('account_deletion_confirm_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Tenés 1 servicio en curso'), findsOneWidget);
      expect(find.text('Tenés 2 pagos pendientes'), findsOneWidget);
      // No refrescó la sesión: el pedido fue rechazado, no aceptado.
      verifyNever(() => authRepository.fetchScope());

      // Act: navegar desde el bloqueante de pago pendiente
      await tester.tap(find.text('Ver').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('pagos'), findsOneWidget);
    },
  );

  testWidgets(
    'un 409 DELETION_ALREADY_REQUESTED muestra el mensaje específico, no un error genérico',
    (tester) async {
      // Arrange
      when(() => repository.requestDeletion()).thenThrow(
        const AccountDeletionAlreadyRequestedFailure(),
      );
      await _pumpScreen(
        tester,
        repository: repository,
        authRepository: authRepository,
      );

      // Act
      await tester.tap(
        find.byKey(const Key('account_deletion_understood_checkbox')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('account_deletion_confirm_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Ya tenés una solicitud de eliminación en curso.'),
        findsOneWidget,
      );
    },
  );
}
