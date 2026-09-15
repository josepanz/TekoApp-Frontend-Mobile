import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_card.dart';
import '../../professional_profile/providers/my_professional_profile_provider.dart';
import '../models/service.dart';

/// Contacto del cliente, visible solo para el profesional asignado a este servicio — mismo
/// criterio de "¿soy el profesional asignado?" que ya usa `ProgressTimeline`
/// (`myProfessionalProfileProvider` vs `service.professional`, nunca `service.userId`/
/// `sessionProvider` directo, ver `service_progress/widgets/progress_timeline.dart`).
///
/// El backend enmascara `email`/`phoneNumber` del cliente (los elimina del JSON, no los manda en
/// `null` explícito) cuando `Users.shareContactInfo=false` (ver `openspec/decisions.md`, Tarea 8
/// de `platform-hardening-2026-09` del backend) — acá ambos llegan como `null` de cualquier forma
/// (`ServiceClientSummary.fromJson` castea con `as String?`). `email` es el campo confiable para
/// distinguir "no compartió" de "no tiene teléfono cargado": a diferencia de `phoneNumber` (ya era
/// opcional antes de esta tarea), `email` es un campo obligatorio de `Users` — si viene `null`,
/// es porque el enmascarado lo sacó, nunca porque el usuario no tiene email.
class ClientContactSection extends ConsumerWidget {
  const ClientContactSection({super.key, required this.service});

  final Service service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myProfessional = ref.watch(myProfessionalProfileProvider).valueOrNull;
    final isAssignedProfessional = myProfessional != null &&
        service.professional != null &&
        myProfessional.referenceId == service.professional!.referenceId;
    if (!isAssignedProfessional) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final client = service.client;
    final sharesContact = client.email != null;

    return TekoCard(
      key: Key('client_contact_section_${service.referenceId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.serviceDetailClientContactTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (!sharesContact)
            Text(
              l10n.serviceDetailClientContactHidden,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else ...[
            _ContactActionRow(
              key: const Key('client_contact_email'),
              icon: Icons.email_outlined,
              label: client.email!,
              onTap: () => launchUrl(Uri(scheme: 'mailto', path: client.email)),
            ),
            if (client.phoneNumber != null) ...[
              const SizedBox(height: 8),
              _ContactActionRow(
                key: const Key('client_contact_phone'),
                icon: Icons.phone_outlined,
                label: client.phoneNumber!,
                onTap: () =>
                    launchUrl(Uri(scheme: 'tel', path: client.phoneNumber)),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ContactActionRow extends StatelessWidget {
  const _ContactActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
