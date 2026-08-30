import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_gradient_background.dart';
import '../../../shared/widgets/teko_password_field.dart';
import '../models/register_failure.dart';
import '../providers/register_controller_provider.dart';

/// Registro público (`POST /onboarding`, ver `AuthRepository.register`) — el usuario queda
/// `PENDING_VERIFICATION` y debe iniciar sesión aparte una vez verificado el email (sin login
/// automático acá, mismo criterio que `RegisterForm` de TekoApp-Web).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;
  bool _acceptTermsTouched = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _acceptTermsTouched = true);
    if (_formKey.currentState?.validate() != true || !_acceptTerms) return;
    ref.read(registerControllerProvider.notifier).submit(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneNumberController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          acceptTerms: _acceptTerms,
        );
  }

  String _errorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      EmailAlreadyRegisteredFailure() =>
        l10n.registerErrorEmailAlreadyRegistered,
      RegisterNoConnectionFailure() => l10n.registerErrorNoConnection,
      RegisterServiceUnavailableFailure() =>
        l10n.registerErrorServiceUnavailable,
      _ => l10n.registerErrorServiceUnavailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final registerState = ref.watch(registerControllerProvider);

    ref.listen<AsyncValue<void>>(registerControllerProvider, (previous, next) {
      final wasLoading = previous?.isLoading ?? false;
      if (wasLoading && !next.isLoading && !next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.registerSuccess)),
        );
        context.go('/login');
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
                  l10n.registerTitle,
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
                          controller: _firstNameController,
                          enabled: !registerState.isLoading,
                          decoration: InputDecoration(
                            labelText: l10n.registerFirstNameLabel,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.registerFirstNameRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          enabled: !registerState.isLoading,
                          decoration: InputDecoration(
                            labelText: l10n.registerLastNameLabel,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.registerLastNameRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          enabled: !registerState.isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.registerEmailLabel,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.registerEmailRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneNumberController,
                          enabled: !registerState.isLoading,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.registerPhoneNumberLabel,
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? l10n.registerPhoneNumberRequired
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        TekoPasswordField(
                          controller: _passwordController,
                          enabled: !registerState.isLoading,
                          labelText: l10n.registerPasswordLabel,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.registerPasswordRequired;
                            }
                            if (value.length < 8) {
                              return l10n.registerPasswordTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TekoPasswordField(
                          controller: _confirmPasswordController,
                          enabled: !registerState.isLoading,
                          labelText: l10n.registerConfirmPasswordLabel,
                          validator: (value) =>
                              value != _passwordController.text
                                  ? l10n.registerPasswordsDoNotMatch
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        // Row simple (no CheckboxListTile): el Container que envuelve este Form
                        // pinta su propio fondo vía BoxDecoration, sin un Material ancestro — un
                        // ListTile ahí adentro no puede pintar su ripple/fondo (ver
                        // legal_consent_screen.dart, que sí usa CheckboxListTile porque está
                        // dentro de un Card, que ya es Material).
                        GestureDetector(
                          onTap: registerState.isLoading
                              ? null
                              : () => setState(
                                    () => _acceptTerms = !_acceptTerms,
                                  ),
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: registerState.isLoading
                                    ? null
                                    : (checked) => setState(
                                          () => _acceptTerms = checked ?? false,
                                        ),
                              ),
                              Expanded(child: Text(l10n.registerAcceptTerms)),
                            ],
                          ),
                        ),
                        if (_acceptTermsTouched && !_acceptTerms)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                l10n.registerAcceptTermsRequired,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        if (registerState.hasError) ...[
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage(l10n, registerState.error),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: registerState.isLoading ? null : _submit,
                          child: registerState.isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.registerSubmit),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(l10n.registerSignIn),
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
