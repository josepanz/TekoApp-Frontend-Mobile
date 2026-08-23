import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/auth/session_state.dart';
import '../../../l10n/app_localizations.dart';
import '../models/push_notification_payload.dart';
import '../providers/push_messaging_provider.dart';
import '../providers/push_registration_controller.dart';

/// Clave global de `ScaffoldMessenger` — este widget vive en `MaterialApp.router(builder: ...)`,
/// por encima del `Navigator`/las pantallas reales, así que `ScaffoldMessenger.of(context)` no
/// encontraría un ancestro válido desde acá. Con la key se puede mostrar el banner de foreground
/// sin depender de qué pantalla esté activa.
final pushNotificationScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

const _permissionPromptedPrefsKey = 'push_permission_prompted';

/// Orquesta las 3 partes del flujo de push (ver `openspec/changes/0005-realtime-and-push.md`):
/// - Login/logout → pedir permiso con contexto (diálogo propio antes del picker nativo del SO) y
///   registrar/dar de baja el token FCM (`PushRegistrationController`).
/// - App abierta (foreground) → el SO no muestra notificación sola, se avisa con un banner propio.
/// - App en background/cerrada → el SO ya mostró la notificación; acá solo se resuelve el deep
///   link al tocarla (`onMessageOpenedApp`) o al abrir la app desde una (`getInitialMessage`).
class PushNotificationGateway extends ConsumerStatefulWidget {
  const PushNotificationGateway({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNotificationGateway> createState() =>
      _PushNotificationGatewayState();
}

class _PushNotificationGatewayState
    extends ConsumerState<PushNotificationGateway> {
  ProviderSubscription<SessionState>? _sessionSubscription;

  @override
  void initState() {
    super.initState();
    _sessionSubscription = ref.listenManual<SessionState>(
      sessionProvider,
      _onSessionChange,
    );
    ref.read(onForegroundMessageProvider)().listen(_onForegroundMessage);
    ref.read(onMessageOpenedAppProvider)().listen(_navigateToPayload);
    _handleInitialMessage();
  }

  @override
  void dispose() {
    _sessionSubscription?.close();
    super.dispose();
  }

  Future<void> _handleInitialMessage() async {
    final message = await ref.read(initialPushMessageReaderProvider)();
    if (message != null) _navigateToPayload(message);
  }

  void _onSessionChange(SessionState? previous, SessionState next) {
    if (next is SessionAuthenticated && previous is! SessionAuthenticated) {
      unawaited(_maybePromptForPermission());
    } else if (next is SessionUnauthenticated &&
        previous is SessionAuthenticated) {
      unawaited(
        ref.read(pushRegistrationControllerProvider.notifier).unregister(),
      );
    }
  }

  Future<void> _maybePromptForPermission() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permissionPromptedPrefsKey) ?? false) return;
    await prefs.setBool(_permissionPromptedPrefsKey, true);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pushPermissionDialogTitle),
        content: Text(l10n.pushPermissionDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.pushPermissionDialogDecline),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.pushPermissionDialogAccept),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await ref
          .read(pushRegistrationControllerProvider.notifier)
          .registerIfPermitted();
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final payload = PushNotificationPayload.fromRemoteMessage(message);
    if (payload.title == null) return;
    final text = payload.body == null
        ? payload.title!
        : '${payload.title} — ${payload.body}';
    pushNotificationScaffoldMessengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(text)));
  }

  void _navigateToPayload(RemoteMessage message) {
    final route = PushNotificationPayload.fromRemoteMessage(message).route;
    if (route != null && mounted) GoRouter.of(context).go(route);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
