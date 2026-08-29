import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../../../shared/widgets/teko_input.dart';
import '../models/service_progress_failure.dart';
import '../providers/service_progress_controller_provider.dart';

Future<void> showAddProgressEntrySheet(
  BuildContext context, {
  required String serviceId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => AddProgressEntrySheet(serviceId: serviceId),
  );
}

/// Bottom sheet de creación de una entrada de bitácora — nota opcional + 0..N fotos, subidas una
/// por una (`ServiceProgressController.addEntry`) antes de crear la entrada en sí. Ver
/// `openspec/changes/0008-work-progress-log.md`.
class AddProgressEntrySheet extends ConsumerStatefulWidget {
  const AddProgressEntrySheet({super.key, required this.serviceId});

  final String serviceId;

  @override
  ConsumerState<AddProgressEntrySheet> createState() =>
      _AddProgressEntrySheetState();
}

class _AddProgressEntrySheetState extends ConsumerState<AddProgressEntrySheet> {
  final _noteController = TextEditingController();
  final List<XFile> _photos = [];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage(maxWidth: 1600);
    if (picked.isEmpty || !mounted) return;
    setState(() => _photos.addAll(picked));
  }

  String _mimeTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    final photos = <PendingProgressPhoto>[];
    for (final xfile in _photos) {
      final Uint8List bytes = await xfile.readAsBytes();
      photos.add(
        (
          bytes: bytes,
          filename: xfile.name,
          mimeType: _mimeTypeFor(xfile.name),
        ),
      );
    }
    if (!mounted) return;

    await ref.read(serviceProgressControllerProvider.notifier).addEntry(
          serviceId: widget.serviceId,
          note: note.isEmpty ? null : note,
          photos: photos,
        );
    if (!mounted) return;

    final state = ref.read(serviceProgressControllerProvider);
    if (!state.hasError) {
      Navigator.of(context).pop();
    }
  }

  String _errorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      ServiceProgressValidationFailure(:final backendMessage) =>
        backendMessage ?? l10n.serviceProgressSubmitError,
      ServiceProgressConflictFailure(:final backendMessage) =>
        backendMessage ?? l10n.serviceProgressSubmitError,
      ServiceProgressForbiddenFailure(:final backendMessage) =>
        backendMessage ?? l10n.serviceProgressSubmitError,
      _ => l10n.serviceProgressSubmitError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(serviceProgressControllerProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.serviceProgressAddButton,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TekoInput(
              key: const Key('progress_entry_note_field'),
              label: l10n.serviceProgressNoteLabel,
              controller: _noteController,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.serviceProgressPhotosLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in _photos)
                  _PickedPhotoThumbnail(photo: photo),
                TekoButton(
                  key: const Key('progress_entry_add_photo_button'),
                  label: l10n.serviceProgressAddPhotoButton,
                  variant: TekoButtonVariant.outline,
                  onPressed: _pickPhotos,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.hasError) ...[
              Text(
                _errorMessage(l10n, state.error),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TekoButton(
                    key: const Key('progress_entry_cancel_button'),
                    label: l10n.serviceProgressCancelButton,
                    variant: TekoButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TekoButton(
                    key: const Key('progress_entry_submit_button'),
                    label: l10n.serviceProgressSubmitButton,
                    loading: state.isLoading,
                    onPressed: state.isLoading ? null : _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniatura de una foto recién elegida, todavía sin subir — lee los bytes del `XFile` una sola
/// vez vía `FutureBuilder` (evita `dart:io File`, que no existe en web; este widget funciona igual
/// en cualquier plataforma que soporte `image_picker`).
class _PickedPhotoThumbnail extends StatelessWidget {
  const _PickedPhotoThumbnail({required this.photo});

  final XFile photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 64,
        child: FutureBuilder<Uint8List>(
          future: photo.readAsBytes(),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes == null) {
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return Image.memory(bytes, fit: BoxFit.cover);
          },
        ),
      ),
    );
  }
}
