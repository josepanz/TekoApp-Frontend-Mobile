import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'teko_button.dart';

/// Wrapper genérico de loading/error/data para pantallas que consumen un `AsyncValue` de
/// Riverpod — evita repetir el mismo `switch`/`when` en cada widget de dominio (regla DRY, ver
/// `.claude/agents/code-reviewer.md`). Reusar esto en vez de escribir el manejo de estados a mano
/// por pantalla.
///
/// `onRetry` es opcional: cuando no se pasa, el estado de error se comporta exactamente igual que
/// antes (sin botón). Cablealo solo donde tenga sentido invalidar el provider y reintentar.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.data,
    required this.builder,
    this.errorMessage,
    this.emptyMessage,
    this.isEmpty = false,
    this.onRetry,
  });

  final bool isLoading;
  final bool hasError;
  final T? data;
  final Widget Function(BuildContext context, T data) builder;
  final String? errorMessage;
  final String? emptyMessage;
  final bool isEmpty;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (hasError || data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage ?? l10n.asyncStateGenericError,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TekoButton(
                label: l10n.asyncStateRetryButton,
                variant: TekoButtonVariant.outline,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      );
    }
    if (isEmpty) {
      return Center(
        child: Text(
          emptyMessage ?? l10n.asyncStateEmpty,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return builder(context, data as T);
  }
}
