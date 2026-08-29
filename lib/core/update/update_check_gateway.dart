import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_available_dialog.dart';
import 'update_check_provider.dart';

/// Corre el chequeo de actualización tras el primer frame (no bloquea el arranque) — mismo patrón
/// que `ConsentGateway`/`PushNotificationGateway` (vive en `MaterialApp.router(builder: ...)`).
/// Solo Android — ver `openspec/specs/app-version-update.md`, "Decisión: alcance Android
/// únicamente".
class UpdateCheckGateway extends ConsumerStatefulWidget {
  const UpdateCheckGateway({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateCheckGateway> createState() => _UpdateCheckGatewayState();
}

class _UpdateCheckGatewayState extends ConsumerState<UpdateCheckGateway> {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    }
  }

  Future<void> _checkForUpdate() async {
    final release = await ref.read(updateCheckProvider.future);
    if (release == null || !mounted) return;
    await showUpdateAvailableDialog(context, release);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
