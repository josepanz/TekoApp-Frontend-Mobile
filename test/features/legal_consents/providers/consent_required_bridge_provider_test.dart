import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/legal_consents/providers/consent_required_bridge_provider.dart';

void main() {
  late ConsentRequiredBridge bridge;

  setUp(() {
    bridge = ConsentRequiredBridge();
  });

  tearDown(() {
    bridge.dispose();
  });

  test(
    'sin listener, requestConsentAndWait se resuelve en false en vez de colgarse (M-06)',
    () async {
      // Arrange — nadie escucha onConsentRequired (StreamController.broadcast no
      // bufferea, el evento se perdería en silencio si lo emitiéramos igual).

      // Act
      final accepted = await bridge.requestConsentAndWait();

      // Assert
      expect(accepted, isFalse);
    },
  );

  test(
    'con listener, emite un evento y espera a que resolve() complete el future',
    () async {
      // Arrange
      final subscription = bridge.onConsentRequired.listen((_) {});

      // Act
      final future = bridge.requestConsentAndWait();
      await pumpEventQueue();
      bridge.resolve(true);

      // Assert
      expect(await future, isTrue);
      await subscription.cancel();
    },
  );

  test(
    'dos requests concurrentes comparten el mismo future: un solo evento emitido, ambos resueltos juntos',
    () async {
      // Arrange
      var eventCount = 0;
      final subscription = bridge.onConsentRequired.listen((_) => eventCount++);

      // Act
      final first = bridge.requestConsentAndWait();
      final second = bridge.requestConsentAndWait();
      await pumpEventQueue();
      bridge.resolve(true);

      // Assert
      expect(eventCount, 1);
      expect(await first, isTrue);
      expect(await second, isTrue);
      await subscription.cancel();
    },
  );

  test('resolve() llamado dos veces no lanza (idempotente)', () async {
    // Arrange
    final subscription = bridge.onConsentRequired.listen((_) {});
    final future = bridge.requestConsentAndWait();
    await pumpEventQueue();

    // Act
    bridge.resolve(false);
    expect(() => bridge.resolve(true), returnsNormally);

    // Assert — la primera resolución es la que vale.
    expect(await future, isFalse);
    await subscription.cancel();
  });
}
