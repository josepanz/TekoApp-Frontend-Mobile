import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'teko_button.dart';
import 'teko_empty_state.dart';

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
    this.loadingBuilder,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyDescription,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.emptyCompact = false,
  });

  final bool isLoading;
  final bool hasError;
  final T? data;
  final Widget Function(BuildContext context, T data) builder;
  final String? errorMessage;
  final String? emptyMessage;
  final bool isEmpty;
  final VoidCallback? onRetry;

  /// Loading opcional (típicamente un `TekoSkeleton`). Si es `null` se mantiene el spinner de
  /// siempre, así los usos existentes no cambian.
  final WidgetBuilder? loadingBuilder;

  /// Personalización del estado vacío (`TekoEmptyState`): ícono, descripción y CTA opcional.
  final IconData emptyIcon;
  final String? emptyDescription;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final bool emptyCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
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
      return TekoEmptyState(
        title: emptyMessage ?? l10n.asyncStateEmpty,
        icon: emptyIcon,
        description: emptyDescription,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
        compact: emptyCompact,
      );
    }
    return builder(context, data as T);
  }
}
