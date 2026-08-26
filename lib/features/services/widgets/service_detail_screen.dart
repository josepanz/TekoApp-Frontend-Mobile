import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ai_disclosure_badge.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../../legal_consents/models/ai_disclosure_entity_type.dart';
import '../../locations/providers/assigned_professional_location_provider.dart';
import '../../ratings/models/rating_failure.dart';
import '../../ratings/models/rating_type.dart';
import '../../ratings/providers/rate_controller_provider.dart';
import '../../ratings/providers/service_ratings_provider.dart';
import '../../ratings/widgets/rate_dialog.dart';
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
          const SizedBox(height: 8),
          AiDisclosureBadge(
            entityType: AiDisclosureEntityType.serviceDescription,
            entityReferenceId: service.id,
          ),
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
          if ((service.status == ServiceStatus.accepted ||
                  service.status == ServiceStatus.inProgress) &&
              service.professional != null) ...[
            const SizedBox(height: 24),
            _AssignedProfessionalTrackingSection(
              professionalId: service.professional!.id,
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
            if (service.professional != null) ...[
              const SizedBox(height: 12),
              _RateProfessionalButton(service: service),
            ],
          ],
        ],
      ),
    );
  }
}

/// Mapa en vivo del profesional asignado — visible mientras el servicio está ACCEPTED/IN_PROGRESS
/// (ver `assignedProfessionalLocationProvider`). Sin ubicación registrada todavía (404 esperado)
/// o mientras carga, no se muestra nada — no es un dato crítico del detalle del servicio.
class _AssignedProfessionalTrackingSection extends ConsumerWidget {
  const _AssignedProfessionalTrackingSection({required this.professionalId});

  final int professionalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final location = ref.watch(
      assignedProfessionalLocationProvider(professionalId),
    );
    final position = location.valueOrNull;
    if (position == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.serviceDetailTrackingTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              key: const Key('assigned_professional_tracking_map'),
              options: MapOptions(
                initialCenter: ll.LatLng(
                  position.latitude,
                  position.longitude,
                ),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.tekoapp.mobile',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ll.LatLng(position.latitude, position.longitude),
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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

/// Botón "calificar profesional" — se oculta si ya existe una calificación
/// `CLIENT_TO_PROFESSIONAL` para este servicio (pedido explícito de la tarea, no solo manejar el
/// 400 `ALREADY_RATED`).
class _RateProfessionalButton extends ConsumerWidget {
  const _RateProfessionalButton({required this.service});

  final Service service;

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    final result = await showRateDialog(context);
    if (result == null || !context.mounted) return;
    final (stars, comment) = result;

    await ref.read(rateControllerProvider.notifier).rateProfessional(
          professionalReferenceId: service.professional!.referenceId,
          serviceId: service.id,
          rating: stars,
          comment: comment,
        );
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(rateControllerProvider);
    final message = switch (state.error) {
      null => l10n.ratingSuccessMessage,
      RatingValidationFailure(:final backendMessage) =>
        backendMessage ?? l10n.ratingError,
      _ => l10n.ratingError,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ratingsAsync = ref.watch(serviceRatingsProvider(service.id));
    final alreadyRated = ratingsAsync.valueOrNull?.any(
      (rating) => rating.type == RatingType.clientToProfessional,
    );
    if (alreadyRated != false) {
      // Todavía cargando, error, o ya calificado — no ofrecer la acción en ninguno de esos casos
      // (el error de red no bloquea el resto de la pantalla, solo esta acción puntual).
      return const SizedBox.shrink();
    }

    final rateState = ref.watch(rateControllerProvider);
    return TekoButton(
      key: Key('rate_professional_button_${service.id}'),
      label: l10n.rateProfessionalButton,
      variant: TekoButtonVariant.outline,
      loading: rateState.isLoading,
      onPressed: rateState.isLoading ? null : () => _rate(context, ref),
    );
  }
}
