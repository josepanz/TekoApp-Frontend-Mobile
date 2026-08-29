import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'apk_actions_providers.dart';
import 'app_release.dart';

/// Modal no descartable (`barrierDismissible: false` + `PopScope(canPop: false)`) — el usuario
/// decide explícitamente Actualizar/Cancelar, ver `openspec/specs/app-version-update.md`, "Flujo
/// del modal". "Cancelar" no tiene memoria: vuelve a aparecer en el próximo chequeo mientras la
/// versión instalada siga desactualizada (decisión de simplicidad, ver "Riesgos" del spec).
Future<void> showUpdateAvailableDialog(
  BuildContext context,
  AppRelease release,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: _UpdateAvailableDialogContent(release: release),
    ),
  );
}

class _UpdateAvailableDialogContent extends ConsumerStatefulWidget {
  const _UpdateAvailableDialogContent({required this.release});

  final AppRelease release;

  @override
  ConsumerState<_UpdateAvailableDialogContent> createState() =>
      _UpdateAvailableDialogContentState();
}

class _UpdateAvailableDialogContentState
    extends ConsumerState<_UpdateAvailableDialogContent> {
  bool _downloading = false;
  double? _progress;
  String? _errorMessage;

  Future<void> _update() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _downloading = true;
      _errorMessage = null;
    });

    String apkPath;
    try {
      apkPath = await ref.read(apkDownloaderProvider).download(
            widget.release.apkDownloadUrl,
            onProgress: (received, total) {
              if (!mounted || total <= 0) return;
              setState(() => _progress = received / total);
            },
          );
    } catch (_) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _errorMessage = l10n.updateDownloadError;
        });
      }
      return;
    }

    final installed = await ref.read(apkInstallerProvider).install(apkPath);
    if (!mounted) return;
    if (installed) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _downloading = false;
        _errorMessage = l10n.updateInstallError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final release = widget.release;

    return AlertDialog(
      title: Text(l10n.updateAvailableTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.updateAvailableVersion(release.tagName)),
          if (release.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(release.notes, maxLines: 6, overflow: TextOverflow.ellipsis),
          ],
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          key: const Key('update_dialog_cancel_button'),
          onPressed: _downloading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.updateCancelButton),
        ),
        TextButton(
          key: const Key('update_dialog_update_button'),
          onPressed: _downloading ? null : _update,
          child: Text(l10n.updateNowButton),
        ),
      ],
    );
  }
}
