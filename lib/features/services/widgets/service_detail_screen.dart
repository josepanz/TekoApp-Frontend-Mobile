import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/service.dart';
import '../models/service_failure.dart';
import '../models/service_request.dart';
import '../models/service_status.dart';
import '../providers/respond_to_request_controller_provider.dart';
import '../providers/service_detail_provider.dart';
import '../providers/service_requests_provider.dart';
import 'service_status_badge.dart';

/// Detalle de un `Service` por su `id` (UUID) — ver `openspec/changes/0003-services-marketplace-core.md`.
class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.serviceDetailTitle)),
      body: switch (serviceAsync) {
        AsyncData(:final value) => _ServiceDetailBody(service: value),
        AsyncError() => Center(child: Text(l10n.serviceDetailError)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ServiceDetailBody extends StatelessWidget {
  const _ServiceDetailBody({required this.service});

  final Service service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(service.title, style: textTheme.titleLarge),
              ),
              ServiceStatusBadge(status: service.status),
            ],
          ),
          if (service.category != null) ...[
            const SizedBox(height: 4),
            Text(service.category!.name, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          Text(service.description),
          const SizedBox(height: 16),
          Text(service.address),
          if (service.professional != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.serviceDetailProfessional(
                '${service.professional!.firstName} ${service.professional!.lastName}',
              ),
            ),
          ],
          if (service.status == ServiceStatus.pending) ...[
            const SizedBox(height: 24),
            Text(l10n.serviceRequestsTitle, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _ServiceRequestsSection(serviceId: service.id),
          ],
          if (service.status == ServiceStatus.completed) ...[
            const SizedBox(height: 24),
            TekoButton(
              key: Key('pay_service_button_${service.id}'),
              label: l10n.payServiceButton,
              onPressed: () => context.push('/pagos/pagar/${service.id}'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Propuestas competidoras sobre un servicio propio PENDING — aceptar una resuelve las demás
/// server-side en una transacción (ver `ServicesRepository.respondToRequest`), nunca se itera
/// rechazándolas desde acá.
///
/// Muestra el profesional solo por su `id` numérico: `ServiceRequestDetailResponseDTO` no anida
/// nombre/datos del profesional (a diferencia de `Service.professional`) — resolverlo requeriría
/// una consulta `GET /professionals/:id` por propuesta, fuera de alcance del checkpoint de esta
/// fase (ver `openspec/changes/0003-services-marketplace-core.md`).
class _ServiceRequestsSection extends ConsumerWidget {
  const _ServiceRequestsSection({required this.serviceId});

  final String serviceId;

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    String requestId,
  ) async {
    await ref
        .read(respondToRequestControllerProvider.notifier)
        .accept(serviceId, requestId);
    if (!context.mounted) return;

    final state = ref.read(respondToRequestControllerProvider);
    if (!state.hasError) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (state.error) {
      ServiceConflictFailure() => l10n.serviceRequestAcceptConflict,
      _ => l10n.serviceRequestAcceptError,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(serviceRequestsProvider(serviceId));
    final requests = requestsAsync.valueOrNull;
    final respondState = ref.watch(respondToRequestControllerProvider);

    return AsyncStateView<List<ServiceRequest>>(
      isLoading: requestsAsync.isLoading,
      hasError: requestsAsync.hasError,
      data: requests,
      isEmpty: requests != null && requests.isEmpty,
      errorMessage: l10n.serviceRequestsError,
      emptyMessage: l10n.serviceRequestsEmpty,
      builder: (context, requests) => Column(
        children: [
          for (final request in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TekoCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.serviceRequestProfessionalLabel(
                              request.professionalId,
                            ),
                          ),
                          if (request.proposedPrice != null)
                            Text(
                              l10n.serviceRequestProposedPrice(
                                request.proposedPrice!.round(),
                              ),
                            ),
                          if (request.message != null) Text(request.message!),
                        ],
                      ),
                    ),
                    TekoButton(
                      key: Key('accept_request_${request.id}'),
                      label: l10n.serviceRequestAccept,
                      loading: respondState.isLoading,
                      onPressed: respondState.isLoading
                          ? null
                          : () => _accept(context, ref, request.id),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
