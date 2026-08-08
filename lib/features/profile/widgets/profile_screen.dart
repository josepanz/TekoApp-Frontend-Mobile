import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Placeholder de contenido (ver + editar perfil, avatar llegan en una fase posterior) — el
/// logout sí es real: limpia `accessToken` + cookie `refreshToken` (ver
/// `AuthRepository.clearSession()`). No navega explícitamente a `/login` — `/perfil` es una ruta
/// protegida, así que el guard de `go_router` (`refreshListenable` en `app.dart`) redirige solo
/// en cuanto la sesión pasa a `SessionUnauthenticated`.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.comingSoon,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(sessionProvider.notifier).logout(),
              child: Text(l10n.logout),
            ),
          ],
        ),
      ),
    );
  }
}
