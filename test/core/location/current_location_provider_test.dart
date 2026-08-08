import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/location/current_location_provider.dart';

void main() {
  test('currentPositionFetcherProvider expone una función invocable', () {
    // Arrange
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Act
    final fetcher = container.read(currentPositionFetcherProvider);

    // Assert
    expect(fetcher, isA<CurrentPositionFetcher>());
  });
}
