import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/data/professional_portfolio_repository.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/models/portfolio_failure.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/models/portfolio_item.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/models/portfolio_review_status.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/providers/professional_portfolio_repository_provider.dart';
import 'package:tekoapp_mobile/features/professional_portfolio/providers/upload_portfolio_item_controller_provider.dart';

class _MockProfessionalPortfolioRepository extends Mock
    implements ProfessionalPortfolioRepository {}

void main() {
  late _MockProfessionalPortfolioRepository repository;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = _MockProfessionalPortfolioRepository();
    container = ProviderContainer(
      overrides: [
        professionalPortfolioRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('sube la foto con los datos recibidos', () async {
    // Arrange
    when(
      () => repository.upload(
        bytes: any(named: 'bytes'),
        filename: any(named: 'filename'),
        mimeType: any(named: 'mimeType'),
        caption: any(named: 'caption'),
      ),
    ).thenAnswer(
      (_) async => PortfolioItem(
        referenceId: 'portfolio-1',
        fileKey: 'abc.jpg',
        sortOrder: 0,
        isVisible: true,
        status: PortfolioReviewStatus.pending,
        createdAt: DateTime.utc(2026, 9, 1),
      ),
    );

    // Act
    await container.read(uploadPortfolioItemControllerProvider.notifier).submit(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'foto.jpg',
          mimeType: 'image/jpeg',
          caption: 'Instalación',
        );

    // Assert
    final state = container.read(uploadPortfolioItemControllerProvider);
    expect(state.hasError, isFalse);
    verify(
      () => repository.upload(
        bytes: any(named: 'bytes'),
        filename: 'foto.jpg',
        mimeType: 'image/jpeg',
        caption: 'Instalación',
      ),
    ).called(1);
  });

  test('deja el estado en error cuando el archivo no es válido (400)',
      () async {
    // Arrange
    when(
      () => repository.upload(
        bytes: any(named: 'bytes'),
        filename: any(named: 'filename'),
        mimeType: any(named: 'mimeType'),
        caption: any(named: 'caption'),
      ),
    ).thenThrow(const PortfolioValidationFailure(null));

    // Act
    await container.read(uploadPortfolioItemControllerProvider.notifier).submit(
          bytes: Uint8List.fromList([1]),
          filename: 'foto.jpg',
          mimeType: 'image/jpeg',
        );

    // Assert
    final state = container.read(uploadPortfolioItemControllerProvider);
    expect(state.error, isA<PortfolioValidationFailure>());
  });
}
