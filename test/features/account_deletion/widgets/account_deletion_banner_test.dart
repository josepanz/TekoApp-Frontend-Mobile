import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/core/auth/session_provider.dart';
import 'package:tekoapp_mobile/core/auth/session_state.dart';
import 'package:tekoapp_mobile/core/auth/user_summary.dart';
import 'package:tekoapp_mobile/features/account_deletion/data/account_deletion_repository.dart';
import 'package:tekoapp_mobile/features/account_deletion/models/account_deletion_failure.dart';
import 'package:tekoapp_mobile/features/account_deletion/providers/account_deletion_repository_provider.dart';
import 'package:tekoapp_mobile/features/account_deletion/widgets/account_deletion_banner.dart';
import 'package:tekoapp_mobile/features/auth/data/auth_repository.dart';
import 'package:tekoapp_mobile/features/auth/providers/auth_repository_provider.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockAccountDeletionRepository extends Mock
    implements AccountDeletionRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

/// `SessionNotifier` real llama a `flutter_secure_storage` al construirse (ver mismo patrón en
/// `test/features/home/widgets/home_screen_test.dart`) — se fija un estado inicial sincrónico.
/// `refreshAfterLogin()` (llamada por los controllers de request/cancel) NO se sobreescribe: usa
/// la implementación real, que pega a `authRepositoryProvider` — mockeado abajo para simular la
/// respuesta fresca de `GET /auth/scope` sin red real.
class _FixedSessionNotifier extends SessionNotifier {
  _FixedSessionNotifier(this._fixed);
  final SessionState _fixed;

  @override
  SessionState build() => _fixed;
}

const _activeUser = UserSummary(
  referenceId: 'ref-1',
  email: 'a@b.com',
  firstName: 'Ana',
  lastName: 'Pérez',
);

final _userPendingDeletion = UserSummary(
  referenceId: 'ref-1',
  email: 'a@b.com',
  firstName: 'Ana',
  lastName: 'Pérez',
  deletionScheduledAt: DateTime(2026, 9, 25),
);

Future<void> _pumpBanner(
  WidgetTester tester, {
  required UserSummary user,
  required _MockAccountDeletionRepository repository,
  required _MockAuthRepository authRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(
          () => _FixedSessionNotifier(SessionAuthenticated(user)),
        ),
        accountDeletionRepositoryProvider.overrideWithValue(repository),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AccountDeletionBanner()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late _MockAccountDeletionRepository repository;
  late _MockAuthRepository authRepository;

  setUp(() {
    repository = _MockAccountDeletionRepository();
    authRepository = _MockAuthRepository();
  });

  testWidgets(
    'no muestra nada cuando la cuenta no tiene una solicitud de borrado activa',
    (tester) async {
      // Arrange & Act
      await _pumpBanner(
        tester,
        user: _activeUser,
        repository: repository,
        authRepository: authRepository,
      );

      // Assert
      expect(find.byKey(const Key('account_deletion_banner')), findsNothing);
    },
  );

  testWidgets(
    'muestra el banner con la fecha cuando hay una solicitud en ventana de gracia',
    (tester) async {
      // Arrange & Act
      await _pumpBanner(
        tester,
        user: _userPendingDeletion,
        repository: repository,
        authRepository: authRepository,
      );

      // Assert
      expect(find.byKey(const Key('account_deletion_banner')), findsOneWidget);
      expect(
        find.byKey(const Key('account_deletion_banner_cancel_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'cancelar refresca la sesión y el banner desaparece (deletionScheduledAt vuelve a null)',
    (tester) async {
      // Arrange
      when(() => repository.cancelDeletion()).thenAnswer((_) async {});
      when(() => authRepository.fetchScope()).thenAnswer(
        (_) async => _activeUser,
      );
      await _pumpBanner(
        tester,
        user: _userPendingDeletion,
        repository: repository,
        authRepository: authRepository,
      );

      // Act
      await tester.tap(
        find.byKey(const Key('account_deletion_banner_cancel_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      verify(() => repository.cancelDeletion()).called(1);
      verify(() => authRepository.fetchScope()).called(1);
      expect(find.byKey(const Key('account_deletion_banner')), findsNothing);
    },
  );

  testWidgets(
    'muestra el mensaje de error cuando cancelar falla porque ya no hay solicitud activa',
    (tester) async {
      // Arrange
      when(() => repository.cancelDeletion()).thenThrow(
        const AccountDeletionNotRequestedFailure(),
      );
      await _pumpBanner(
        tester,
        user: _userPendingDeletion,
        repository: repository,
        authRepository: authRepository,
      );

      // Act
      await tester.tap(
        find.byKey(const Key('account_deletion_banner_cancel_button')),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text(
          'No tenés ninguna solicitud de eliminación activa para cancelar.',
        ),
        findsOneWidget,
      );
      // No debería haber intentado refrescar la sesión si cancelar falló.
      verifyNever(() => authRepository.fetchScope());
    },
  );
}
