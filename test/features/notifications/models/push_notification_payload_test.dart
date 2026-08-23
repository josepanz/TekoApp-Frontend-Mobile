import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/notifications/models/push_notification_payload.dart';

void main() {
  group('PushNotificationPayload.fromRemoteMessage', () {
    test('parsea título, cuerpo, tipo y referenceId', () {
      // Arrange
      const message = RemoteMessage(
        notification: RemoteNotification(
          title: 'Servicio aceptado',
          body: 'Ana aceptó tu pedido',
        ),
        data: {'type': 'service_accepted', 'referenceId': 'service-uuid-1'},
      );

      // Act
      final payload = PushNotificationPayload.fromRemoteMessage(message);

      // Assert
      expect(payload.title, 'Servicio aceptado');
      expect(payload.body, 'Ana aceptó tu pedido');
      expect(payload.type, 'service_accepted');
      expect(payload.referenceId, 'service-uuid-1');
    });

    test('trata un referenceId vacío como ausente', () {
      // Arrange
      const message =
          RemoteMessage(data: {'type': 'system', 'referenceId': ''});

      // Act
      final payload = PushNotificationPayload.fromRemoteMessage(message);

      // Assert
      expect(payload.referenceId, isNull);
    });
  });

  group('route', () {
    test('resuelve servicios a /mis-servicios/:id', () {
      for (final type in [
        'service_request',
        'service_accepted',
        'service_rejected',
        'service_completed',
      ]) {
        final payload = PushNotificationPayload(
          title: null,
          body: null,
          type: type,
          referenceId: 'service-uuid-1',
        );
        expect(payload.route, '/mis-servicios/service-uuid-1');
      }
    });

    test('resuelve pagos a /pagos/historial/:id', () {
      const payload = PushNotificationPayload(
        title: null,
        body: null,
        type: 'payment_received',
        referenceId: 'payment-uuid-1',
      );
      expect(payload.route, '/pagos/historial/payment-uuid-1');
    });

    test('no resuelve ruta sin referenceId', () {
      const payload = PushNotificationPayload(
        title: null,
        body: null,
        type: 'service_accepted',
        referenceId: null,
      );
      expect(payload.route, isNull);
    });

    test('no resuelve ruta para tipos sin pantalla propia', () {
      const payload = PushNotificationPayload(
        title: null,
        body: null,
        type: 'rating_received',
        referenceId: 'rating-uuid-1',
      );
      expect(payload.route, isNull);
    });
  });
}
