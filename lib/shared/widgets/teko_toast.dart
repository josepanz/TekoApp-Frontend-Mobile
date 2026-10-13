import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum TekoToastVariant { success, error, info }

/// Helper único para feedback efímero (reemplaza a `SnackBar` directos). Variantes
/// success/error/info con color e ícono desde tokens del tema (`TekoSemanticColors` y
/// `ColorScheme.error`), acción opcional y semántica `liveRegion` para que TalkBack/VoiceOver lo
/// anuncien al aparecer. El fondo es la superficie inversa del tema (contraste AA en light/dark);
/// el color de la variante se aplica al ícono, nunca como único canal de información.
class TekoToast {
  TekoToast._();

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context,
    String message, {
    TekoToastVariant variant = TekoToastVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    return showOn(
      ScaffoldMessenger.of(context),
      Theme.of(context),
      message,
      variant: variant,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Variante para quien tiene un `ScaffoldMessengerState` global (ej. el gateway de push, que
  /// vive fuera del árbol de `Scaffold`s).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showOn(
    ScaffoldMessengerState messenger,
    ThemeData theme,
    String message, {
    TekoToastVariant variant = TekoToastVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final colorScheme = theme.colorScheme;
    final semantic = theme.extension<TekoSemanticColors>();
    final (IconData icon, Color accent) = switch (variant) {
      TekoToastVariant.success => (
          Icons.check_circle_outline,
          semantic?.success ?? colorScheme.primary,
        ),
      TekoToastVariant.error => (Icons.error_outline, colorScheme.error),
      TekoToastVariant.info => (
          Icons.info_outline,
          semantic?.info ?? colorScheme.tertiary,
        ),
    };
    final foreground = colorScheme.surface;

    return messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.onSurface,
        duration: duration,
        content: Semantics(
          liveRegion: true,
          container: true,
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, color: accent)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
            ],
          ),
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: accent,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}
