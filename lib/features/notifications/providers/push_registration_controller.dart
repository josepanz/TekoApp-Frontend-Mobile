import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/fcm_token_storage_provider.dart';
import '../models/notifications_failure.dart';
import 'notifications_repository_provider.dart';
import 'push_messaging_provider.dart';

/// Registro/baja del token FCM del dispositivo — quien dispara esto es
/// `PushNotificationGateway` reaccionando a `sessionProvider` (login → registrar si hay permiso,
/// logout → dar de baja). El pedido de permiso con contexto (mostrar por qué antes de la
/// ventana nativa del SO) es responsabilidad de la UI, no de este controller — acá solo se asume
/// que el permiso ya fue concedido cuando se llama `registerIfPermitted`.
class PushRegistrationController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> registerIfPermitted() async {
    final granted = await ref.read(notificationPermissionRequesterProvider)();
    if (!granted) return;

    final token = await ref.read(fcmTokenReaderProvider)();
    if (token == null) return;

    final deviceType = ref.read(currentDeviceTypeProvider);
    try {
      final referenceId = await ref
          .read(notificationsRepositoryProvider)
          .registerFcmToken(token: token, deviceType: deviceType);
      await ref.read(fcmTokenReferenceWriterProvider)(referenceId);
    } on NotificationsFailure {
      // Best-effort — un push no registrado no debe bloquear el login.
    }
  }

  Future<void> unregister() async {
    final referenceId = await ref.read(fcmTokenReferenceReaderProvider)();
    if (referenceId == null) return;

    try {
      await ref
          .read(notificationsRepositoryProvider)
          .removeFcmToken(referenceId);
    } on NotificationsFailure {
      // Best-effort — el logout no debe fallar por esto.
    }
    await ref.read(fcmTokenReferenceClearerProvider)();
  }
}

final pushRegistrationControllerProvider =
    AsyncNotifierProvider<PushRegistrationController, void>(
  PushRegistrationController.new,
);
