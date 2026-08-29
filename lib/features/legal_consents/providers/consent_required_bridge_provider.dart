import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Puente entre `ConsentRequiredInterceptor` (dio, sin `BuildContext`) y `ConsentGateway` (widget,
/// escucha [onConsentRequired] y navega). El interceptor llama [requestConsentAndWait] y queda
/// esperando la respuesta del usuario; el gateway resuelve con [resolve] al volver de la pantalla
/// de aceptación.
///
/// Si dos requests fallan con `CONSENT_REQUIRED` casi al mismo tiempo, ambos esperan el MISMO
/// [Future] (no se abren dos pantallas de aceptación en paralelo) — se resuelven juntos cuando el
/// usuario completa (o cancela) el único flujo mostrado.
class ConsentRequiredBridge {
  Completer<bool>? _pending;
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onConsentRequired => _controller.stream;

  Future<bool> requestConsentAndWait() {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      return pending.future;
    }
    final completer = Completer<bool>();
    _pending = completer;
    _controller.add(null);
    return completer.future;
  }

  void resolve(bool accepted) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.complete(accepted);
    }
  }

  void dispose() => _controller.close();
}

final consentRequiredBridgeProvider = Provider<ConsentRequiredBridge>((ref) {
  final bridge = ConsentRequiredBridge();
  ref.onDispose(bridge.dispose);
  return bridge;
});
