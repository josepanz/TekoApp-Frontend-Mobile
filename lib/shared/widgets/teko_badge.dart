import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum TekoBadgeVariant { neutral, success, warning, info, destructive }

/// Badge de estado — equivalente a `TekoApp-Web/src/components/ui/badge.tsx`. Siempre lleva
/// texto (nunca solo un punto de color, ver `.claude/rules/design-system.md` — "el estado no
/// depende solo del color"). `success`/`warning`/`info`/`destructive` nunca reusan
/// `primary`/`accent` — el teal/verde de marca significa "marca", no "estado".
class TekoBadge extends StatelessWidget {
  const TekoBadge({
    super.key,
    required this.label,
    this.variant = TekoBadgeVariant.neutral,
  });

  final String label;
  final TekoBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<TekoSemanticColors>();

    final color = switch (variant) {
      TekoBadgeVariant.neutral => colorScheme.onSurfaceVariant,
      TekoBadgeVariant.success => semantic?.success ?? colorScheme.primary,
      TekoBadgeVariant.warning => semantic?.warning ?? colorScheme.primary,
      TekoBadgeVariant.info => semantic?.info ?? colorScheme.primary,
      TekoBadgeVariant.destructive => colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
