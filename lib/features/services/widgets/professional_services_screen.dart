import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/service.dart';
import '../models/service_failure.dart';
import '../models/service_status.dart';
import '../providers/my_professional_services_provider.dart';
import '../providers/service_transition_controller_provider.dart';
import 'service_status_badge.dart';

/// Modo profesional: mis servicios asignados, con acción de marcar en progreso/completado (ver
/// `openspec/changes/0003-services-marketplace-core.md`).
class ProfessionalServicesScreen extends ConsumerStatefulWidget {
  const ProfessionalServicesScreen({super.key});

  @override
  ConsumerState<ProfessionalServicesScreen> createState() =>
      _ProfessionalServicesScreenState();
}

class _ProfessionalServicesScreenState
    extends ConsumerState<ProfessionalServicesScreen> {
  String? _actingServiceId;

  Future<void> _start(String serviceId) => _run(
        serviceId,
        () => ref
            .read(serviceTransitionControllerProvider.notifier)
            .start(serviceId),
      );

  Future<void> _complete(String serviceId) => _run(
        serviceId,
        () => ref
            .read(serviceTransitionControllerProvider.notifier)
            .complete(serviceId),
      );

  Future<void> _run(String serviceId, Future<void> Function() action) async {
    setState(() => _actingServiceId = serviceId);
    await action();
    if (!mounted) return;

    final state = ref.read(serviceTransitionControllerProvider);
    if (state.hasError) {
      final l10n = AppLocalizations.of(context)!;
      final message = switch (state.error) {
        ServiceConflictFailure() => l10n.professionalServicesConflict,
        _ => l10n.professionalServicesError,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    setState(() => _actingServiceId = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final servicesAsync = ref.watch(myProfessionalServicesProvider);
    final services = servicesAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.professionalServicesTitle)),
      body: AsyncStateView<List<Service>>(
        isLoading: servicesAsync.isLoading,
        hasError: servicesAsync.hasError,
        data: services,
        isEmpty: services != null && services.isEmpty,
        errorMessage: l10n.professionalServicesLoadError,
        emptyMessage: l10n.professionalServicesEmpty,
        builder: (context, services) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final service = services[index];
            final isActing = _actingServiceId == service.id;
            return TekoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      ServiceStatusBadge(status: service.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(service.address),
                  if (service.status == ServiceStatus.accepted ||
                      service.status == ServiceStatus.inProgress) ...[
                    const SizedBox(height: 12),
                    TekoButton(
                      key: Key('service_transition_${service.id}'),
                      label: service.status == ServiceStatus.accepted
                          ? l10n.professionalServicesStart
                          : l10n.professionalServicesComplete,
                      loading: isActing,
                      onPressed: isActing
                          ? null
                          : () => service.status == ServiceStatus.accepted
                              ? _start(service.id)
                              : _complete(service.id),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
