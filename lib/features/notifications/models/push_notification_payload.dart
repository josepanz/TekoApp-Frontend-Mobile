import 'package:firebase_messaging/firebase_messaging.dart';

/// Un push recibido — `RemoteMessage.data` siempre trae `referenceId`/`type` como string plano
/// (ver `FcmProviderService.send` en el backend, nunca objetos anidados en `data`, es una
/// restricción de FCM). `type` es uno de los valores de `NotificationType` del backend
/// (`notification-type.enum.ts`) — acá solo se usa para decidir a qué pantalla navegar.
class PushNotificationPayload {
  const PushNotificationPayload({
    required this.title,
    required this.body,
    required this.type,
    required this.referenceId,
  });

  final String? title;
  final String? body;
  final String type;
  final String? referenceId;

  factory PushNotificationPayload.fromRemoteMessage(RemoteMessage message) {
    return PushNotificationPayload(
      title: message.notification?.title,
      body: message.notification?.body,
      type: message.data['type'] as String? ?? '',
      referenceId: (message.data['referenceId'] as String?)?.isEmpty ?? true
          ? null
          : message.data['referenceId'] as String?,
    );
  }

  /// Ruta de `go_router` a la que navegar al tocar la notificación — `null` si no hay pantalla
  /// específica (cae a home). Los servicios no tienen hoy una pantalla de detalle propia del lado
  /// profesional (`/profesional/mis-servicios` es solo listado) ni las calificaciones tienen una
  /// pantalla de detalle individual — se resuelve al mejor destino disponible hoy, revisar si se
  /// agregan esas pantallas.
  String? get route {
    if (referenceId == null) return null;
    return switch (type) {
      'service_request' ||
      'service_accepted' ||
      'service_rejected' ||
      'service_completed' =>
        '/mis-servicios/$referenceId',
      'payment_received' => '/pagos/historial/$referenceId',
      _ => null,
    };
  }
}
