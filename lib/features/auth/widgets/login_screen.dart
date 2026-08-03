import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Pantalla placeholder — el formulario real (email + password, nonce + RSA-OAEP contra el
/// backend) se implementa en la Fase 0002 (ver `.claude/rules/auth.md`). Este esqueleto solo fija
/// la ruta y el layout mínimo para que `go_router` tenga un destino real para el guard de sesión.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.loginTitle, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(labelText: l10n.loginEmailLabel),
                enabled: false,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(labelText: l10n.loginPasswordLabel),
                obscureText: true,
                enabled: false,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: null,
                child: Text(l10n.loginSubmit),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.comingSoon,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
