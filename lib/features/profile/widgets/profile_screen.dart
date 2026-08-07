import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Pantalla placeholder — ruta protegida real desde la Fase 0001 (usada para validar el mecanismo
/// de redirect de `go_router` antes de tener sesión real). El contenido (ver + editar perfil,
/// avatar) se implementa en la Fase 0002, ver `.claude/rules/auth.md`.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: Center(
        child: Text(
          l10n.comingSoon,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
