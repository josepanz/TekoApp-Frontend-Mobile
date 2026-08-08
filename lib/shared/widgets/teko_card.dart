import 'package:flutter/material.dart';

/// Contenedor base compartido — equivalente a `TekoApp-Web/src/components/ui/card.tsx`. Usa
/// `cardColor`/`colorScheme.outline` del tema activo, nunca un color hardcodeado.
class TekoCard extends StatelessWidget {
  const TekoCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: child,
    );
  }
}
