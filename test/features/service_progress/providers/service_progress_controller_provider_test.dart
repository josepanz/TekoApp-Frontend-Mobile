import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/service_progress/data/service_progress_repository.dart';
import 'package:tekoapp_mobile/features/service_progress/models/service_progress_entry.dart';
import 'package:tekoapp_mobile/features/service_progress/models/service_progress_failure.dart';
import 'package:tekoapp_mobile/features/service_progress/providers/service_progress_controller_provider.dart';
import 'package:tekoapp_mobile/features/service_progress/providers/service_progress_repository_provider.dart';

class _MockServiceProgressRepository extends Mock
    implements ServiceProgressRepository {}

ServiceProgressEntry _entry() {
  return ServiceProgressEntry(
    referenceId: 'entry-1',
    note: 'Avance',
    images: const ['key-1.jpg'],
    entryOrder: 1,
    createdAt: DateTime.utc(2026, 8, 27),
    editWindowExpired: false,
  );
}

void main() {
  late _MockServiceProgressRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = _MockServiceProgressRepository();
    container = ProviderContainer(
      overrides: [
        serviceProgressRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('addEntry', () {
    test('sube cada foto antes de crear la entrada, en ese orden', () async {
      // Arrange
      when(
        () => repository.uploadImage(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          mimeType: any(named: 'mimeType'),
        ),
      ).thenAnswer((_) async => 'key-1.jpg');
      when(
        () => repository.createEntry(
          serviceId: any(named: 'serviceId'),
          note: any(named: 'note'),
          images: any(named: 'images'),
        ),
      ).thenAnswer((_) async => _entry());

      // Act
      await container.read(serviceProgressControllerProvider.notifier).addEntry(
            serviceId: 'svc-1',
            note: 'Avance',
            photos: [
              (
                bytes: Uint8List.fromList([1, 2, 3]),
                filename: 'foto.jpg',
                mimeType: 'image/jpeg',
              ),
            ],
          );

      // Assert
      verifyInOrder([
        () => repository.uploadImage(
              bytes: any(named: 'bytes'),
              filename: 'foto.jpg',
              mimeType: 'image/jpeg',
            ),
        () => repository.createEntry(
              serviceId: 'svc-1',
              note: 'Avance',
              images: ['key-1.jpg'],
            ),
      ]);
    });

    test('crea la entrada sin fotos cuando no se adjuntó ninguna', () async {
      // Arrange
      when(
        () => repository.createEntry(
          serviceId: any(named: 'serviceId'),
          note: any(named: 'note'),
          images: any(named: 'images'),
        ),
      ).thenAnswer((_) async => _entry());

      // Act
      await container
          .read(serviceProgressControllerProvider.notifier)
          .addEntry(serviceId: 'svc-1', note: 'Solo texto');

      // Assert
      verifyNever(
        () => repository.uploadImage(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          mimeType: any(named: 'mimeType'),
        ),
      );
      verify(
        () => repository.createEntry(
          serviceId: 'svc-1',
          note: 'Solo texto',
          images: const [],
        ),
      ).called(1);
    });

    test('deja el estado en error si la subida de una foto falla', () async {
      // Arrange
      when(
        () => repository.uploadImage(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          mimeType: any(named: 'mimeType'),
        ),
      ).thenThrow(const ServiceProgressServiceUnavailableFailure());

      // Act
      await container.read(serviceProgressControllerProvider.notifier).addEntry(
            serviceId: 'svc-1',
            photos: [
              (
                bytes: Uint8List.fromList([1]),
                filename: 'foto.jpg',
                mimeType: 'image/jpeg',
              ),
            ],
          );

      // Assert
      final state = container.read(serviceProgressControllerProvider);
      expect(state.hasError, isTrue);
      verifyNever(
        () => repository.createEntry(
          serviceId: any(named: 'serviceId'),
          note: any(named: 'note'),
          images: any(named: 'images'),
        ),
      );
    });
  });

  group('deleteEntry', () {
    test('deja el estado en error cuando venció la ventana de corrección', () async {
      // Arrange
      when(
        () => repository.deleteEntry(
          serviceId: any(named: 'serviceId'),
          entryId: any(named: 'entryId'),
        ),
      ).thenThrow(const ServiceProgressConflictFailure('venció'));

      // Act
      await container
          .read(serviceProgressControllerProvider.notifier)
          .deleteEntry(serviceId: 'svc-1', entryId: 'entry-1');

      // Assert
      final state = container.read(serviceProgressControllerProvider);
      expect(state.error, isA<ServiceProgressConflictFailure>());
    });
  });
}
