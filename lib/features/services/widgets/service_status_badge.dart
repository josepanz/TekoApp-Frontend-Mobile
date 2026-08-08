import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_badge.dart';
import '../models/service_status.dart';

/// Traduce un `ServiceStatus` a un `TekoBadge` — un solo lugar para mantener la etiqueta y el
/// color semántico consistentes entre "mis servicios", el detalle y las pantallas de profesional.
class ServiceStatusBadge extends StatelessWidget {
  const ServiceStatusBadge({super.key, required this.status});

  final ServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, variant) = switch (status) {
      ServiceStatus.pending => (
          l10n.serviceStatusPending,
          TekoBadgeVariant.warning,
        ),
      ServiceStatus.accepted => (
          l10n.serviceStatusAccepted,
          TekoBadgeVariant.info,
        ),
      ServiceStatus.inProgress => (
          l10n.serviceStatusInProgress,
          TekoBadgeVariant.info,
        ),
      ServiceStatus.completed => (
          l10n.serviceStatusCompleted,
          TekoBadgeVariant.success,
        ),
      ServiceStatus.cancelled => (
          l10n.serviceStatusCancelled,
          TekoBadgeVariant.destructive,
        ),
    };
    return TekoBadge(label: label, variant: variant);
  }
}
