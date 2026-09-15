import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/teko_button.dart';
import '../providers/upload_portfolio_item_controller_provider.dart';

Future<void> showUploadPortfolioItemSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const UploadPortfolioItemSheet(),
  );
}

/// Bottom sheet de carga de una foto de portafolio — solo foto (cámara/galería vía
/// `image_picker`, mismo patrón que `UploadDocumentSheet`) + caption opcional.
class UploadPortfolioItemSheet extends ConsumerStatefulWidget {
  const UploadPortfolioItemSheet({super.key});

  @override
  ConsumerState<UploadPortfolioItemSheet> createState() =>
      _UploadPortfolioItemSheetState();
}

class _UploadPortfolioItemSheetState
    extends ConsumerState<UploadPortfolioItemSheet> {
  XFile? _photo;
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, maxWidth: 2000);
    if (picked == null || !mounted) return;
    setState(() => _photo = picked);
  }

  String _mimeTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) return;

    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    await ref.read(uploadPortfolioItemControllerProvider.notifier).submit(
          bytes: bytes,
          filename: photo.name,
          mimeType: _mimeTypeFor(photo.name),
          caption: _captionController.text.trim().isEmpty
              ? null
              : _captionController.text.trim(),
        );
    if (!mounted) return;

    final state = ref.read(uploadPortfolioItemControllerProvider);
    if (!state.hasError) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(uploadPortfolioItemControllerProvider);

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
                    key: const Key('upload_portfolio_camera_button'),
                    label: l10n.uploadPortfolioItemTakePhoto,
                    variant: TekoButtonVariant.outline,
                    onPressed: () => _pickPhoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TekoButton(
                    key: const Key('upload_portfolio_gallery_button'),
                    label: l10n.uploadPortfolioItemChooseFromGallery,
                    variant: TekoButtonVariant.outline,
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('upload_portfolio_caption_field'),
              controller: _captionController,
              decoration: InputDecoration(hintText: l10n.portfolioCaptionHint),
            ),
            const SizedBox(height: 16),
            if (state.hasError) ...[
              Text(
                l10n.uploadPortfolioItemError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TekoButton(
                    key: const Key('upload_portfolio_cancel_button'),
                    label: l10n.uploadPortfolioItemCancelButton,
                    variant: TekoButtonVariant.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TekoButton(
                    key: const Key('upload_portfolio_submit_button'),
                    label: l10n.uploadPortfolioItemSubmitButton,
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
