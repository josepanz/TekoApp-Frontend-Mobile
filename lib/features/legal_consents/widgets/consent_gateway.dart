import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/consent_required_bridge_provider.dart';

/// Orquesta el puente entre `ConsentRequiredInterceptor` (dio, sin `BuildContext`) y la navegación
/// real — mismo patrón que `PushNotificationGateway` (vive en `MaterialApp.router(builder: ...)`,
/// usa `GoRouter.of(context)` desde el `context` de este propio widget). Al recibir un evento de
/// [ConsentRequiredBridge.onConsentRequired], navega a `/legal/consentimiento` y espera; el
/// resultado (aceptó o canceló) resuelve el `Future` que el interceptor tiene pendiente.
class ConsentGateway extends ConsumerStatefulWidget {
  const ConsentGateway({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConsentGateway> createState() => _ConsentGatewayState();
}

class _ConsentGatewayState extends ConsumerState<ConsentGateway> {
  StreamSubscription<void>? _subscription;
  bool _isShowingConsentFlow = false;

  @override
  void initState() {
    super.initState();
    _subscription = ref
        .read(consentRequiredBridgeProvider)
        .onConsentRequired
        .listen((_) => unawaited(_handleConsentRequired()));
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _handleConsentRequired() async {
    if (_isShowingConsentFlow || !mounted) return;
    _isShowingConsentFlow = true;
    final accepted = await GoRouter.of(
      context,
    ).push<bool>('/legal/consentimiento');
    _isShowingConsentFlow = false;
    ref.read(consentRequiredBridgeProvider).resolve(accepted ?? false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
