import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_gradient_background.dart';
import '../models/login_failure.dart';
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

  String _errorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      InvalidCredentialsFailure() => l10n.loginErrorInvalidCredentials,
      NoConnectionFailure() => l10n.loginErrorNoConnection,
      ServiceUnavailableFailure() => l10n.loginErrorServiceUnavailable,
      _ => l10n.loginErrorServiceUnavailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginState = ref.watch(loginControllerProvider);

    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
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
                          enabled: !loginState.isLoading,
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
                        TextFormField(
                          controller: _passwordController,
                          enabled: !loginState.isLoading,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.loginPasswordLabel,
                          ),
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
                          onPressed: loginState.isLoading ? null : _submit,
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
