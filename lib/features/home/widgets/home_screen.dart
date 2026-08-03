import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Pantalla de inicio placeholder — el selector de modo (cliente/profesional, ver
/// `.claude/rules/flutter-architecture.md#multi-rol-en-una-sola-app`) y el contenido real llegan
/// en fases posteriores. Sirve hoy para tener un destino inicial real que `flutter run` pueda
/// mostrar y para validar que el esqueleto (tema, routing, l10n) arranca sin errores.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Text(
          l10n.comingSoon,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
