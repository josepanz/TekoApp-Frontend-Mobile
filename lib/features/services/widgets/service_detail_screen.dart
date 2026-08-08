import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../models/service.dart';
import '../providers/service_detail_provider.dart';
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
        ],
      ),
    );
  }
}
