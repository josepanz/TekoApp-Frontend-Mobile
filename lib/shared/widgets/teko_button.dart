import 'package:flutter/material.dart';

enum TekoButtonVariant { primary, secondary, outline, ghost, destructive }

enum TekoButtonSize { sm, md, lg }

/// Botón base compartido — variantes equivalentes a `TekoApp-Web/src/components/ui/button.tsx`
/// (`default`→`primary`, `secondary`, `outline`, `ghost`, `destructive`; `link` no se portó, no
/// hay un caso de uso todavía). Nunca colores hardcodeados: siempre `Theme.of(context).colorScheme`
/// (ver `.claude/rules/design-system.md`).
class TekoButton extends StatelessWidget {
  const TekoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = TekoButtonVariant.primary,
    this.size = TekoButtonSize.md,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final TekoButtonVariant variant;
  final TekoButtonSize size;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisabled = onPressed == null || loading;

    final (Color background, Color foreground, Color? border) =
        switch (variant) {
      TekoButtonVariant.primary => (
          colorScheme.primary,
          colorScheme.onPrimary,
          null,
        ),
      TekoButtonVariant.secondary => (
          colorScheme.secondary,
          colorScheme.onSecondary,
          null,
        ),
      TekoButtonVariant.outline => (
          Colors.transparent,
          colorScheme.onSurface,
          colorScheme.outline,
        ),
      TekoButtonVariant.ghost => (
          Colors.transparent,
          colorScheme.onSurface,
          null,
        ),
      TekoButtonVariant.destructive => (
          colorScheme.error.withValues(alpha: 0.1),
          colorScheme.error,
          null,
        ),
    };

    // Alto mínimo 44px en todos los tamaños — target táctil, ver rules/design-system.md (más
    // crítico en mobile que en web, donde `sm` puede ser más chico).
    final height = switch (size) {
      TekoButtonSize.sm => 44.0,
      TekoButtonSize.md => 48.0,
      TekoButtonSize.lg => 56.0,
    };

    final content = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style:
                    TextStyle(color: foreground, fontWeight: FontWeight.w600),
              ),
            ],
          );

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: background.withValues(alpha: 0.5),
          elevation: 0,
          side: border != null ? BorderSide(color: border) : BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: content,
      ),
    );
  }
}
