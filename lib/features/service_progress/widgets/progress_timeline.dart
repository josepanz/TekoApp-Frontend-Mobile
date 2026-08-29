import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/async_state_view.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_card.dart';
import '../../professional_profile/providers/my_professional_profile_provider.dart';
import '../../services/models/service.dart';
import '../../services/models/service_status.dart';
import '../models/service_progress_entry.dart';
import '../providers/service_progress_controller_provider.dart';
import '../providers/service_progress_photo_url_provider.dart';
import '../providers/service_progress_provider.dart';
import 'add_progress_entry_sheet.dart';

/// Sección embebida en `ServiceDetailScreen` (ambos roles la ven) — ver
/// `openspec/changes/0008-work-progress-log.md`. El botón "Agregar avance" solo se muestra al
/// profesional asignado (comparando `myProfessionalProfileProvider` contra `service.professional`,
/// nunca contra `service.userId`/`sessionProvider` directo — son UUIDs de entidades distintas,
/// `Professionals.referenceId` vs `Users.referenceId`) y solo mientras el servicio está
/// ACCEPTED/IN_PROGRESS.
class ProgressTimeline extends ConsumerWidget {
  const ProgressTimeline({super.key, required this.service});

  final Service service;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ServiceProgressEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.serviceProgressDeleteConfirmTitle),
        content: Text(l10n.serviceProgressDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.serviceProgressCancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.serviceProgressDeleteButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(serviceProgressControllerProvider.notifier).deleteEntry(
          serviceId: service.referenceId,
          entryId: entry.referenceId,
        );
    if (!context.mounted) return;

    final state = ref.read(serviceProgressControllerProvider);
    if (!state.hasError) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.serviceProgressDeleteError)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(
      serviceProgressProvider(service.referenceId),
    );
    final entries = entriesAsync.valueOrNull;
    final myProfessional = ref.watch(myProfessionalProfileProvider).valueOrNull;
    final canAdd = myProfessional != null &&
        service.professional != null &&
        myProfessional.referenceId == service.professional!.referenceId &&
        (service.status == ServiceStatus.accepted ||
            service.status == ServiceStatus.inProgress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.serviceProgressSectionTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AsyncStateView<List<ServiceProgressEntry>>(
          isLoading: entriesAsync.isLoading,
          hasError: entriesAsync.hasError,
          data: entries,
          isEmpty: entries != null && entries.isEmpty,
          errorMessage: l10n.serviceProgressError,
          emptyMessage: l10n.serviceProgressEmpty,
          builder: (context, entries) => Column(
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProgressEntryTile(
                    entry: entry,
                    canDelete: myProfessional != null &&
                        service.professional != null &&
                        myProfessional.referenceId ==
                            service.professional!.referenceId &&
                        !entry.editWindowExpired,
                    onDelete: () => _delete(context, ref, l10n, entry),
                  ),
                ),
            ],
          ),
        ),
        if (canAdd) ...[
          const SizedBox(height: 12),
          TekoButton(
            key: Key('add_progress_entry_button_${service.referenceId}'),
            label: l10n.serviceProgressAddButton,
            variant: TekoButtonVariant.outline,
            onPressed: () => showAddProgressEntrySheet(
              context,
              serviceId: service.referenceId,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressEntryTile extends StatelessWidget {
  const _ProgressEntryTile({
    required this.entry,
    required this.canDelete,
    required this.onDelete,
  });

  final ServiceProgressEntry entry;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TekoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).languageCode,
                  ).add_Hm().format(entry.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (canDelete)
                IconButton(
                  key: Key('delete_progress_entry_${entry.referenceId}'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.serviceProgressDeleteButton,
                  onPressed: onDelete,
                ),
            ],
          ),
          if (entry.note != null && entry.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(entry.note!),
          ],
          if (entry.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entry.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    _ProgressEntryPhoto(imageKey: entry.images[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressEntryPhoto extends ConsumerWidget {
  const _ProgressEntryPhoto({required this.imageKey});

  final String imageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(serviceProgressPhotoUrlProvider(imageKey));
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 72,
        height: 72,
        child: switch (urlAsync) {
          AsyncData(:final value) => Image.network(
              value,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
            ),
          AsyncError() => const _PhotoPlaceholder(),
          _ => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        },
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.broken_image_outlined),
    );
  }
}
