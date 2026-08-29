import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/service_progress/data/service_progress_repository.dart';
import 'package:tekoapp_mobile/features/service_progress/models/service_progress_entry.dart';
import 'package:tekoapp_mobile/features/service_progress/models/service_progress_failure.dart';
import 'package:tekoapp_mobile/features/service_progress/providers/service_progress_repository_provider.dart';
import 'package:tekoapp_mobile/features/service_progress/widgets/add_progress_entry_sheet.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockServiceProgressRepository extends Mock
    implements ServiceProgressRepository {}

Future<void> _pumpSheet(
  WidgetTester tester,
  _MockServiceProgressRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serviceProgressRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddProgressEntrySheet(
                  context,
                  serviceId: 'svc-1',
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  late _MockServiceProgressRepository repository;

  setUp(() {
    repository = _MockServiceProgressRepository();
  });

  testWidgets('guarda la entrada solo con nota y cierra el sheet', (
    tester,
  ) async {
    // Arrange
    when(
      () => repository.createEntry(
        serviceId: any(named: 'serviceId'),
        note: any(named: 'note'),
        images: any(named: 'images'),
      ),
    ).thenAnswer(
      (_) async => ServiceProgressEntry(
        referenceId: 'entry-1',
        note: 'Avance',
        images: const [],
        entryOrder: 1,
        createdAt: DateTime.utc(2026, 8, 27),
        editWindowExpired: false,
      ),
    );
    await _pumpSheet(tester, repository);

    // Act
    await tester.enterText(
      find.byKey(const Key('progress_entry_note_field')),
      'Avance',
    );
    await tester.tap(find.byKey(const Key('progress_entry_submit_button')));
    await tester.pumpAndSettle();

    // Assert
    verify(
      () => repository.createEntry(
        serviceId: 'svc-1',
        note: 'Avance',
        images: const [],
      ),
    ).called(1);
    expect(find.byKey(const Key('progress_entry_note_field')), findsNothing);
  });

  testWidgets('muestra el mensaje del backend cuando la creación falla', (
    tester,
  ) async {
    // Arrange
    when(
      () => repository.createEntry(
        serviceId: any(named: 'serviceId'),
        note: any(named: 'note'),
        images: any(named: 'images'),
      ),
    ).thenThrow(
      const ServiceProgressConflictFailure(
        'El servicio ya no está en curso',
      ),
    );
    await _pumpSheet(tester, repository);

    // Act
    await tester.tap(find.byKey(const Key('progress_entry_submit_button')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('El servicio ya no está en curso'), findsOneWidget);
    expect(find.byKey(const Key('progress_entry_note_field')), findsOneWidget);
  });

  testWidgets('el botón cancelar cierra el sheet sin llamar al backend', (
    tester,
  ) async {
    // Arrange
    await _pumpSheet(tester, repository);

    // Act
    await tester.tap(find.byKey(const Key('progress_entry_cancel_button')));
    await tester.pumpAndSettle();

    // Assert
    verifyNever(
      () => repository.createEntry(
        serviceId: any(named: 'serviceId'),
        note: any(named: 'note'),
        images: any(named: 'images'),
      ),
    );
    expect(find.byKey(const Key('progress_entry_note_field')), findsNothing);
  });
}
