import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/service.dart';
import '../models/service_failure.dart';
import '../providers/available_services_provider.dart';
import '../providers/propose_on_service_controller_provider.dart';

/// Modo profesional: servicios PENDING disponibles en mi categoría + acción de proponerme (ver
/// `openspec/changes/0003-services-marketplace-core.md`). Reemplaza el placeholder de
/// `ProfessionalHomeScreen` del Paso 5+6.
class AvailableServicesScreen extends ConsumerStatefulWidget {
  const AvailableServicesScreen({super.key});

  @override
  ConsumerState<AvailableServicesScreen> createState() =>
      _AvailableServicesScreenState();
}

class _AvailableServicesScreenState
    extends ConsumerState<AvailableServicesScreen> {
  String? _proposingServiceId;

  Future<void> _propose(String serviceId) async {
    setState(() => _proposingServiceId = serviceId);
    await ref.read(proposeOnServiceControllerProvider.notifier).submit(
          serviceId,
        );
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(proposeOnServiceControllerProvider);
    final message = state.hasError
        ? _errorMessage(l10n, state.error)
        : l10n.availableServicesProposeSuccess;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() => _proposingServiceId = null);
  }

  String _errorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      ServiceConflictFailure() => l10n.availableServicesProposeConflict,
      _ => l10n.availableServicesProposeError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final servicesAsync = ref.watch(availableServicesProvider);
    final services = servicesAsync.valueOrNull;

    return AsyncStateView<List<Service>>(
      isLoading: servicesAsync.isLoading,
      hasError: servicesAsync.hasError,
      data: services,
      isEmpty: services != null && services.isEmpty,
      errorMessage: l10n.availableServicesError,
      emptyMessage: l10n.availableServicesEmpty,
      builder: (context, services) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: services.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final service = services[index];
          final isProposing = _proposingServiceId == service.id;
          return TekoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(service.address),
                const SizedBox(height: 12),
                TekoButton(
                  key: Key('propose_button_${service.id}'),
                  label: l10n.availableServicesProposeButton,
                  loading: isProposing,
                  onPressed: isProposing ? null : () => _propose(service.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
