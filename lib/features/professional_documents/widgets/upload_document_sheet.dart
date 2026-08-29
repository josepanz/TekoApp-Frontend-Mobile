import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../models/professional_document_failure.dart';
import '../models/professional_document_type.dart';
import '../providers/upload_document_controller_provider.dart';

Future<void> showUploadDocumentSheet(
  BuildContext context, {
  required ProfessionalDocumentType documentType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => UploadDocumentSheet(documentType: documentType),
  );
}

/// Bottom sheet de carga de un documento — solo foto (cámara/galería vía `image_picker`), sin
/// adjuntar PDF nativo todavía (no hay `file_picker` en el proyecto — evaluar como tarea aparte si
/// se necesita, ver `openspec/decisions.md`). El archivo viaja en el mismo POST que crea el
/// documento (multipart directo, a diferencia de `service_progress`).
class UploadDocumentSheet extends ConsumerStatefulWidget {
  const UploadDocumentSheet({super.key, required this.documentType});

  final ProfessionalDocumentType documentType;

  @override
  ConsumerState<UploadDocumentSheet> createState() =>
      _UploadDocumentSheetState();
}

class _UploadDocumentSheetState extends ConsumerState<UploadDocumentSheet> {
  XFile? _photo;
  DateTime? _issuedAt;

  Future<void> _pickPhoto(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, maxWidth: 2000);
    if (picked == null || !mounted) return;
    setState(() => _photo = picked);
  }

  Future<void> _pickIssuedAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _issuedAt ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _issuedAt = picked);
  }

  String _mimeTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) return;

    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    await ref.read(uploadDocumentControllerProvider.notifier).submit(
          professionalDocumentTypeReferenceId: widget.documentType.referenceId,
          bytes: bytes,
          filename: photo.name,
          mimeType: _mimeTypeFor(photo.name),
          issuedAt: _issuedAt,
        );
    if (!mounted) return;

    final state = ref.read(uploadDocumentControllerProvider);
    if (!state.hasError) {
      Navigator.of(context).pop();
    }
  }

  String _errorMessage(AppLocalizations l10n, Object? error) {
    return switch (error) {
      ProfessionalDocumentValidationFailure(:final backendMessage) =>
        backendMessage ?? l10n.uploadDocumentError,
      ProfessionalDocumentTypeNotApplicableFailure(:final backendMessage) =>
        backendMessage ?? l10n.uploadDocumentError,
      _ => l10n.uploadDocumentError,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(uploadDocumentControllerProvider);

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
              widget.documentType.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.documentType.description != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.documentType.description!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            if (_photo != null)
              FutureBuilder<Uint8List>(
                future: _photo!.readAsBytes(),
                builder: (context, snapshot) {
                  final bytes = snapshot.data;
                  if (bytes == null) return const SizedBox.shrink();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      bytes,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TekoButton(
                    key: const Key('upload_document_camera_button'),
                    label: l10n.uploadDocumentTakePhoto,
                    variant: TekoButtonVariant.outline,
                    onPressed: () => _pickPhoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TekoButton(
                    key: const Key('upload_document_gallery_button'),
                    label: l10n.uploadDocumentChooseFromGallery,
                    variant: TekoButtonVariant.outline,
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TekoButton(
              key: const Key('upload_document_issued_at_button'),
              label: _issuedAt == null
                  ? l10n.uploadDocumentIssuedAtButton
                  : l10n.uploadDocumentIssuedAtSelected(
                      '${_issuedAt!.day}/${_issuedAt!.month}/${_issuedAt!.year}',
                    ),
              variant: TekoButtonVariant.ghost,
              onPressed: _pickIssuedAt,
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
                    key: const Key('upload_document_cancel_button'),
                    label: l10n.uploadDocumentCancelButton,
                    variant: TekoButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TekoButton(
                    key: const Key('upload_document_submit_button'),
                    label: l10n.uploadDocumentSubmitButton,
                    loading: state.isLoading,
                    onPressed:
                        (_photo == null || state.isLoading) ? null : _submit,
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
