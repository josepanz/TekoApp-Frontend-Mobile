import 'package:flutter/material.dart';

import '../../design_system/tokens.generated.dart';

/// Gradiente diagonal navy→teal→verde inspirado en el banner de `brand/manual-de-marca.png`
/// (`TekoApp-Frontend-Web`) — única referencia real de gradiente de marca hoy. Usa los shades
/// 700/600 (no los 500 crudos de `TekoPrimitives`) para que texto blanco encima pase contraste AA
/// en TODA la superficie — mismo criterio que `TekoThemeColors.light.primary` usa `primary600` en
/// vez de `primary500` (ver comentario en `tokens.generated.dart`). Contenedor puro (sin padding
/// propio) — el caller decide si es fondo de página completa o un hero acotado con
/// `BorderRadius`.
class TekoGradientBackground extends StatelessWidget {
  const TekoGradientBackground({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TekoPrimitives.neutral900,
            TekoPrimitives.accent700,
            TekoPrimitives.primary600,
          ],
          stops: [0, 0.55, 1],
        ),
      ),
      child: child,
    );
  }
}
