import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/current_location_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_input.dart';
import '../../categories/models/category.dart';
import '../../categories/models/service_type.dart';
import '../../categories/providers/categories_provider.dart';
import '../../categories/providers/service_types_provider.dart';
import '../models/service_failure.dart';
import '../providers/request_service_controller_provider.dart';

/// Modo cliente: pedir un servicio — categoría → tipo → descripción → ubicación → confirmar (ver
/// `openspec/changes/0003-services-marketplace-core.md`). Crea un `Service` en PENDING.
class RequestServiceScreen extends ConsumerStatefulWidget {
  const RequestServiceScreen({super.key});

  @override
  ConsumerState<RequestServiceScreen> createState() =>
      _RequestServiceScreenState();
}

class _RequestServiceScreenState extends ConsumerState<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  Category? _selectedCategory;
  ServiceType? _selectedServiceType;
  DeviceLatLng? _location;
  LocationFailure? _locationError;
  bool _isLocating = false;
  bool _locationMissing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });
    try {
      final location = await ref.read(currentPositionFetcherProvider)();
      if (!mounted) return;
      setState(() {
        _location = location;
        _locationMissing = false;
      });
    } on LocationFailure catch (error) {
      if (!mounted) return;
      setState(() => _locationError = error);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _submit() {
    final isFormValid = _formKey.currentState?.validate() == true;
    final location = _location;
    setState(() => _locationMissing = location == null);
    if (!isFormValid || location == null) return;

    ref.read(requestServiceControllerProvider.notifier).submit(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategory!.id,
          serviceTypeId: _selectedServiceType!.id,
          latitude: location.latitude,
          longitude: location.longitude,
          address: _addressController.text.trim(),
        );
  }

  String _locationErrorMessage(AppLocalizations l10n, LocationFailure error) {
    return switch (error) {
      LocationServiceDisabledFailure() =>
        l10n.requestServiceLocationServiceDisabled,
      LocationPermissionDeniedFailure() =>
        l10n.requestServiceLocationPermissionDenied,
    };
  }

  String _submitErrorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      ServiceValidationFailure() => l10n.requestServiceErrorValidation,
      _ => l10n.requestServiceErrorServiceUnavailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(categoriesProvider);
    final serviceTypesAsync = ref.watch(serviceTypesProvider);
    final submitState = ref.watch(requestServiceControllerProvider);

    ref.listen(requestServiceControllerProvider, (previous, next) {
      // `AsyncNotifier<void>` conserva `hasValue=true` incluso en error una vez que tuvo un
      // valor previo (semántica "seamless" de Riverpod que preserva el último valor bueno) —
      // `!hasError` es la señal correcta de "terminó bien", `hasValue` no sirve acá.
      if (previous?.isLoading == true && !next.hasError) {
        Navigator.of(context).maybePop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestServiceTitle)),
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
                  key: const Key('request_service_category_field'),
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.requestServiceCategoryLabel,
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
                      ? l10n.requestServiceCategoryRequired
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              AsyncStateView<List<ServiceType>>(
                isLoading: serviceTypesAsync.isLoading,
                hasError: serviceTypesAsync.hasError,
                data: serviceTypesAsync.valueOrNull,
                errorMessage: l10n.requestServiceCatalogError,
                builder: (context, serviceTypes) =>
                    DropdownButtonFormField<ServiceType>(
                  key: const Key('request_service_type_field'),
                  initialValue: _selectedServiceType,
                  decoration: InputDecoration(
                    labelText: l10n.requestServiceTypeLabel,
                  ),
                  items: [
                    for (final serviceType in serviceTypes)
                      DropdownMenuItem(
                        value: serviceType,
                        child: Text(serviceType.name),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedServiceType = value),
                  validator: (value) =>
                      value == null ? l10n.requestServiceTypeRequired : null,
                ),
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.requestServiceTitleFieldLabel,
                controller: _titleController,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.requestServiceTitleRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.requestServiceDescriptionLabel,
                controller: _descriptionController,
                maxLines: 4,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.requestServiceDescriptionRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TekoInput(
                label: l10n.requestServiceAddressLabel,
                controller: _addressController,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.requestServiceAddressRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TekoButton(
                key: const Key('request_service_locate_button'),
                label: l10n.requestServiceUseMyLocation,
                variant: TekoButtonVariant.outline,
                loading: _isLocating,
                onPressed: _isLocating ? null : _useCurrentLocation,
              ),
              if (_location != null) ...[
                const SizedBox(height: 8),
                Text(l10n.requestServiceLocationCaptured),
              ],
              if (_locationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _locationErrorMessage(l10n, _locationError!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_locationMissing && _location == null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.requestServiceLocationRequired,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (submitState.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  _submitErrorMessage(l10n, submitState.error),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              TekoButton(
                key: const Key('request_service_submit_button'),
                label: l10n.requestServiceSubmit,
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
