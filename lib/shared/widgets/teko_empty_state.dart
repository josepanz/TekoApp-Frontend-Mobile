import 'package:flutter/material.dart';

import 'teko_button.dart';

/// Estado vacío con ícono, título, descripción opcional y CTA opcional (patrón Airbnb: el vacío
/// siempre ofrece un siguiente paso cuando existe uno). Colores solo desde el tema; el ícono es
/// decorativo (el título ya lo describe) y el bloque se anuncia como una unidad.
class TekoEmptyState extends StatelessWidget {
  const TekoEmptyState({
    super.key,
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.description,
    this.actionLabel,
    this.onAction,
    this.actionSemanticsIdentifier,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? actionSemanticsIdentifier;

  /// Versión reducida para secciones embebidas en otras pantallas (ícono chico, poco padding).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final body = Padding(
      padding: EdgeInsets.all(compact ? 8 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: compact ? 32 : 56,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            container: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                if (description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    description!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            TekoButton(
              label: actionLabel!,
              onPressed: onAction,
              semanticsIdentifier: actionSemanticsIdentifier,
            ),
          ],
        ],
      ),
    );
    // Scroll solo en la versión de pantalla completa: ante poca altura (teclado, split) no debe
    // desbordar. La compacta vive dentro de otros layouts y no scrollea.
    return compact
        ? Center(child: body)
        : Center(child: SingleChildScrollView(child: body));
  }
}
