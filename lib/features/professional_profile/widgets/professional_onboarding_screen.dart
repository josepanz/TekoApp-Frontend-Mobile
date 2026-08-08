import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_input.dart';
import '../../categories/models/category.dart';
import '../../categories/providers/categories_provider.dart';
import '../models/professional_profile_failure.dart';
import '../providers/professional_onboarding_controller_provider.dart';

/// Modo profesional: activar perfil profesional (`POST /professionals`) — ver
/// `openspec/changes/0003-services-marketplace-core.md`.
class ProfessionalOnboardingScreen extends ConsumerStatefulWidget {
  const ProfessionalOnboardingScreen({super.key});

  @override
  ConsumerState<ProfessionalOnboardingScreen> createState() =>
      _ProfessionalOnboardingScreenState();
}

class _ProfessionalOnboardingScreenState
    extends ConsumerState<ProfessionalOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _fixedRateController = TextEditingController();
  final _yearsOfExperienceController = TextEditingController();
  final _skillsController = TextEditingController();

  Category? _selectedCategory;

  @override
  void dispose() {
    _descriptionController.dispose();
    _hourlyRateController.dispose();
    _fixedRateController.dispose();
    _yearsOfExperienceController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  List<String>? _parseSkills() {
    final raw = _skillsController.text.trim();
    if (raw.isEmpty) return null;
    return raw
        .split(',')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    ref.read(professionalOnboardingControllerProvider.notifier).submit(
          categoryId: _selectedCategory!.id,
          description: _descriptionController.text.trim(),
          hourlyRate: double.parse(_hourlyRateController.text.trim()),
          fixedRate: _fixedRateController.text.trim().isEmpty
              ? null
              : double.parse(_fixedRateController.text.trim()),
          yearsOfExperience: _yearsOfExperienceController.text.trim().isEmpty
              ? null
              : int.parse(_yearsOfExperienceController.text.trim()),
          skills: _parseSkills(),
        );
  }

  String _submitErrorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      ProfessionalProfileValidationFailure() =>
        l10n.professionalOnboardingErrorValidation,
      _ => l10n.professionalOnboardingErrorServiceUnavailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final submitState = ref.watch(professionalOnboardingControllerProvider);

    ref.listen(professionalOnboardingControllerProvider, (previous, next) {
      // `AsyncNotifier<void>` conserva `hasValue=true` incluso en error una vez que produjo un
      // valor — `!hasError` es la señal correcta de "terminó bien" (ver
      // `request_service_screen.dart` para el mismo hallazgo).
      if (previous?.isLoading == true && !next.hasError) {
        context.go('/profesional');
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.professionalOnboardingTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AsyncStateView<List<Category>>(
                isLoading: categoriesAsync.isLoading,
                hasError: categoriesAsync.hasError,
                data: categoriesAsync.valueOrNull,
                errorMessage: l10n.requestServiceCatalogError,
                builder: (context, categories) =>
                    DropdownButtonFormField<Category>(
                  key: const Key('professional_onboarding_category_field'),
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.professionalOnboardingCategoryLabel,
                  ),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                  validator: (value) => value == null
                      ? l10n.professionalOnboardingCategoryRequired
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.professionalOnboardingDescriptionLabel,
                controller: _descriptionController,
                maxLines: 4,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.professionalOnboardingDescriptionRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.professionalOnboardingHourlyRateLabel,
                controller: _hourlyRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed < 0) {
                    return l10n.professionalOnboardingHourlyRateRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.professionalOnboardingFixedRateLabel,
                controller: _fixedRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.professionalOnboardingYearsOfExperienceLabel,
                controller: _yearsOfExperienceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.professionalOnboardingSkillsLabel,
                controller: _skillsController,
              ),
              if (submitState.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  _submitErrorMessage(l10n, submitState.error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              TekoButton(
                key: const Key('professional_onboarding_submit_button'),
                label: l10n.professionalOnboardingSubmit,
                loading: submitState.isLoading,
                onPressed: submitState.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
