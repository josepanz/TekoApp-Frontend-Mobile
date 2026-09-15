import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/biometric_device_supported_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_gradient_background.dart';
import '../../../shared/widgets/teko_password_field.dart';
import '../models/login_failure.dart';
import '../providers/biometric_login_available_provider.dart';
import '../providers/biometric_login_controller_provider.dart';
import '../providers/biometric_opt_in_controller_provider.dart';
import '../providers/login_controller_provider.dart';

/// Login real (ver `openspec/specs/auth-and-session.md`): 3 estados de error visualmente
/// distinguidos (credenciales inválidas / sin conexión / servidor no disponible) — nunca
/// colapsados entre sí.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    ref.read(loginControllerProvider.notifier).submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _submitBiometric(AppLocalizations l10n) {
    ref
        .read(biometricLoginControllerProvider.notifier)
        .submit(localizedReason: l10n.loginBiometricReason);
  }

  String _errorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      InvalidCredentialsFailure() => l10n.loginErrorInvalidCredentials,
      NoConnectionFailure() => l10n.loginErrorNoConnection,
      ServiceUnavailableFailure() => l10n.loginErrorServiceUnavailable,
      _ => l10n.loginErrorServiceUnavailable,
    };
  }

  /// Tras un login normal exitoso (nunca en la restauración transparente de sesión al abrir la
  /// app, ver `openspec/specs/biometric-login.md` — esta pantalla solo se ve tras un logout
  /// explícito o cuando no hay sesión previa que restaurar), ofrece activar el opt-in biométrico
  /// si el dispositivo lo soporta y todavía no estaba activo. Cualquiera sea la respuesta,
  /// termina navegando a home — este diálogo nunca bloquea el login en sí, ni siquiera si algo
  /// de esta parte falla inesperadamente (ver el `try/catch` de abajo: un login real no puede
  /// quedar colgado por un feature opcional, mismo criterio que M-06 con el flujo de
  /// consentimiento).
  Future<void> _handleLoginSuccess() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final alreadyEnabled = await ref.read(
        biometricOptInControllerProvider.future,
      );
      if (!alreadyEnabled) {
        final supported = await ref.read(
          biometricDeviceSupportedProvider.future,
        );
        if (supported && mounted) {
          final accepted = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.loginBiometricOptInTitle),
              content: Text(l10n.loginBiometricOptInBody),
              actions: [
                TextButton(
                  key: const Key('login_biometric_optin_decline_button'),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.loginBiometricOptInDecline),
                ),
                FilledButton(
                  key: const Key('login_biometric_optin_accept_button'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.loginBiometricOptInAccept),
                ),
              ],
            ),
          );
          if (accepted == true) {
            await ref
                .read(biometricOptInControllerProvider.notifier)
                .enable(email: email, password: password);
          }
        }
      }
    } catch (_) {
      // El opt-in biométrico es una conveniencia opcional, nunca una condición para completar
      // un login que ya fue exitoso contra el backend.
    }

    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.watch(loginControllerProvider);
    final biometricLoginState = ref.watch(biometricLoginControllerProvider);
    final biometricAvailable =
        ref.watch(biometricLoginAvailableProvider).valueOrNull ?? false;
    final isBusy = loginState.isLoading || biometricLoginState.isLoading;

    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      final wasLoading = previous?.isLoading ?? false;
      if (wasLoading && !next.isLoading && !next.hasError) {
        unawaited(_handleLoginSuccess());
      }
    });

    ref.listen<AsyncValue<void>>(biometricLoginControllerProvider, (
      previous,
      next,
    ) {
      final wasLoading = previous?.isLoading ?? false;
      if (wasLoading && !next.isLoading && !next.hasError) {
        context.go('/');
      }
    });

    return Scaffold(
      body: TekoGradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.loginTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          enabled: !isBusy,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.loginEmailLabel,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.loginEmailRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TekoPasswordField(
                          controller: _passwordController,
                          enabled: !isBusy,
                          labelText: l10n.loginPasswordLabel,
                          validator: (value) => (value == null || value.isEmpty)
                              ? l10n.loginPasswordRequired
                              : null,
                        ),
                        if (loginState.hasError) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage(l10n, loginState.error),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: isBusy ? null : _submit,
                          child: loginState.isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.loginSubmit),
                        ),
                        if (biometricAvailable) ...[
                          const SizedBox(height: 12),
                          OutlinedButton(
                            key: const Key('login_biometric_button'),
                            onPressed:
                                isBusy ? null : () => _submitBiometric(l10n),
                            child: biometricLoginState.isLoading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.loginBiometricButton),
                          ),
                        ],
                        if (biometricLoginState.hasError) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage(l10n, biometricLoginState.error),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text(
                            '${l10n.loginNoAccount} ${l10n.loginSignUp}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
