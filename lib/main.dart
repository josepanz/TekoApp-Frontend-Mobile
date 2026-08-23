import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (_) {
    // Sin proyecto Firebase configurado en esta plataforma todavía (ej. iOS sin
    // GoogleService-Info.plist, o CI) — la app sigue funcionando sin push, ver
    // features/notifications/widgets/push_notification_gateway.dart.
  }
  runApp(const ProviderScope(child: TekoApp()));
}

/// El SO ya muestra la notificación solo (payload `notification`, ver
/// `FcmProviderService.send` en el backend) — este handler no procesa nada, solo necesita existir
/// y estar registrado para que `firebase_messaging` funcione en Android con la app cerrada.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
