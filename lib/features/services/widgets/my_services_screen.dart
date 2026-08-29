import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_card.dart';
import '../models/service.dart';
import '../providers/my_client_services_provider.dart';
import 'service_status_badge.dart';

/// Modo cliente: listado de "mis servicios" (todos los estados), con detalle por servicio (ver
/// `openspec/changes/0003-services-marketplace-core.md`).
class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final servicesAsync = ref.watch(myClientServicesProvider);
    final services = servicesAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myServicesTitle)),
      body: AsyncStateView<List<Service>>(
        isLoading: servicesAsync.isLoading,
        hasError: servicesAsync.hasError,
        data: services,
        isEmpty: services != null && services.isEmpty,
        errorMessage: l10n.myServicesError,
        emptyMessage: l10n.myServicesEmpty,
        builder: (context, services) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final service = services[index];
            return GestureDetector(
              key: Key('service_item_${service.referenceId}'),
              onTap: () =>
                  context.push('/mis-servicios/${service.referenceId}'),
              child: TekoCard(
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
