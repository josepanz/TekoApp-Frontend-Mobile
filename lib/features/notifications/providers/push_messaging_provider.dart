import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device_type.dart';

/// Wrappers finos sobre `firebase_messaging`/`dart:io` detrás de providers de función — mismo
/// patrón que `currentPositionFetcherProvider`/`accessTokenReaderProvider` (ver
/// `.claude/rules/test.md`), para que los tests los overrideen sin tocar el plugin real.
typedef NotificationPermissionRequester = Future<bool> Function();
typedef FcmTokenReader = Future<String?> Function();
typedef PushMessageStreamOpener = Stream<RemoteMessage> Function();
typedef InitialPushMessageReader = Future<RemoteMessage?> Function();

final notificationPermissionRequesterProvider =
    Provider<NotificationPermissionRequester>((ref) {
  return () async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  };
});

final fcmTokenReaderProvider = Provider<FcmTokenReader>((ref) {
  return FirebaseMessaging.instance.getToken;
});

final onForegroundMessageProvider = Provider<PushMessageStreamOpener>((ref) {
  return () => FirebaseMessaging.onMessage;
});

final onMessageOpenedAppProvider = Provider<PushMessageStreamOpener>((ref) {
  return () => FirebaseMessaging.onMessageOpenedApp;
});

final initialPushMessageReaderProvider = Provider<InitialPushMessageReader>((
  ref,
) {
  return FirebaseMessaging.instance.getInitialMessage;
});

final currentDeviceTypeProvider = Provider<DeviceType>((ref) {
  return Platform.isIOS ? DeviceType.ios : DeviceType.android;
});
