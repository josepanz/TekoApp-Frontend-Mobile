import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/auth/session_provider.dart';
import '../../../core/auth/session_state.dart';
import '../../../core/auth/user_summary.dart';
import '../../../core/locale/locale_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_avatar.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_input.dart';
import '../models/profile_failure.dart';
import '../providers/update_profile_controller_provider.dart';
import '../providers/upload_avatar_controller_provider.dart';

/// "Mi perfil": ver + editar nombre/apellido/teléfono y avatar (ver
/// `openspec/changes/0002-auth-and-design-system.md`). El logout ya era real desde el Paso 5 de
/// la Fase 0002.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

/// `null` = seguir el idioma del sistema operativo (ver `core/locale/locale_provider.dart`).
class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeControllerProvider).valueOrNull;

    return Row(
      children: [
        Expanded(child: Text(l10n.profileLanguageLabel)),
        DropdownButton<String?>(
          key: const Key('profile_language_selector'),
          value: locale?.languageCode,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(l10n.profileLanguageSystem),
            ),
            DropdownMenuItem(
              value: 'es',
              child: Text(l10n.profileLanguageSpanish),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text(l10n.profileLanguageEnglish),
            ),
          ],
          onChanged: (code) => ref
              .read(localeControllerProvider.notifier)
              .setLocale(code == null ? null : Locale(code)),
        ),
      ],
    );
  }
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  UserSummary? _initializedFor;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Los controllers se completan una sola vez por usuario logueado — si el usuario ya empezó a
  /// editar, un refresh de sesión (ej. tras guardar) no debe pisarle lo que está escribiendo.
  void _ensureControllersInitialized(UserSummary user) {
    if (_initializedFor?.referenceId == user.referenceId) return;
    _initializedFor = user;
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _phoneController.text = user.phoneNumber ?? '';
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    await ref.read(uploadAvatarControllerProvider.notifier).submit(
          bytes: bytes,
          filename: picked.name,
          mimeType: _mimeTypeFor(picked.name),
        );
  }

  String _mimeTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  void _submit(UserSummary user) {
    if (_formKey.currentState?.validate() != true) return;
    ref.read(updateProfileControllerProvider.notifier).submit(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );
  }

  String _updateErrorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      ProfileValidationFailure() => l10n.profileErrorValidation,
      _ => l10n.profileErrorServiceUnavailable,
    };
  }

  String _avatarErrorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      AvatarTooLargeFailure() => l10n.avatarErrorTooLarge,
      AvatarUnsupportedTypeFailure() => l10n.avatarErrorUnsupportedType,
      _ => l10n.avatarErrorUpload,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(sessionProvider);
    final updateState = ref.watch(updateProfileControllerProvider);
    final avatarState = ref.watch(uploadAvatarControllerProvider);

    if (session is SessionServiceUnavailable) {
      // 5xx/sin conexión NUNCA implica "no hay sesión" (ver specs/auth-and-session.md) — el
      // guard de go_router deliberadamente no redirige a login acá, así que esta pantalla tiene
      // que mostrar algo estable en vez de un spinner infinito (pumpAndSettle jamás converge con
      // un CircularProgressIndicator eterno — se detectó escribiendo el test, no en producción).
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: Center(child: Text(l10n.profileServiceUnavailable)),
      );
    }

    if (session is! SessionAuthenticated) {
      // SessionUnknown (todavía resolviendo) o, defensivamente, SessionUnauthenticated (el guard
      // de go_router ya está redirigiendo a /login en este instante) — spinner transitorio.
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = session.user;
    _ensureControllersInitialized(user);
    final isSaving = updateState.isLoading || avatarState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: avatarState.isLoading ? null : _pickAndUploadAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      TekoAvatar(
                        name: '${user.firstName} ${user.lastName}',
                        avatarUrl: user.avatarUrl,
                        size: TekoAvatarSize.lg,
                      ),
                      if (avatarState.isLoading)
                        const Positioned.fill(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Semantics(
                          button: true,
                          label: l10n.profileChangeAvatar,
                          child: const CircleAvatar(
                            radius: 14,
                            child: Icon(Icons.edit, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (avatarState.hasError) ...[
                const SizedBox(height: 8),
                Text(
                  _avatarErrorMessage(l10n, avatarState.error),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              Text(user.email, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TekoInput(
                label: l10n.profileFirstNameLabel,
                controller: _firstNameController,
                enabled: !isSaving,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.profileFirstNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.profileLastNameLabel,
                controller: _lastNameController,
                enabled: !isSaving,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.profileLastNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.profilePhoneLabel,
                controller: _phoneController,
                enabled: !isSaving,
                keyboardType: TextInputType.phone,
              ),
              if (updateState.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  _updateErrorMessage(l10n, updateState.error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              TekoButton(
                key: const Key('profile_save_button'),
                label: l10n.profileSave,
                loading: updateState.isLoading,
                onPressed: isSaving ? null : () => _submit(user),
              ),
              const SizedBox(height: 24),
              const _LanguageSelector(),
              const SizedBox(height: 12),
              TekoButton(
                key: const Key('profile_privacy_and_data_button'),
                label: l10n.profileLinkPrivacyAndData,
                variant: TekoButtonVariant.ghost,
                onPressed: () => context.push('/perfil/privacidad-y-datos'),
              ),
              const SizedBox(height: 12),
              TekoButton(
                key: const Key('profile_logout_button'),
                label: l10n.logout,
                variant: TekoButtonVariant.outline,
                onPressed: () => ref.read(sessionProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
