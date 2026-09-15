import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Encapsula el patrón "resolver URL presignada → `Image.network` → placeholder ante error o
/// mientras carga", duplicado antes en portafolio (`public_portfolio_section.dart`,
/// `my_portfolio_screen.dart`). Las URLs de S3 que consume esta app expiran a los 900s
/// (`.claude/rules/auth.md`) — si la pantalla queda abierta más tiempo, o la resolución falla,
/// este widget degrada a un placeholder estático en vez de mostrar el ícono de imagen rota de
/// Flutter.
///
/// `TekoAvatar` (`teko_avatar.dart`) y `ProgressTimeline` (`progress_timeline.dart`) implementan
/// el mismo patrón de forma independiente — son candidatos a migrar a este widget más adelante,
/// pero no en esta tarea: ya funcionan y tienen tests propios.
class ResolvedNetworkImage extends StatelessWidget {
  const ResolvedNetworkImage({
    super.key,
    required this.urlAsync,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  /// Estado de la resolución de la URL presignada (ver `portfolioFileUrlProvider` y equivalentes).
  final AsyncValue<String> urlAsync;
  final double width;
  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return switch (urlAsync) {
      AsyncData(:final value) => Image.network(
          value,
          width: width,
          height: height,
          fit: fit,
          // Ante una URL presignada vencida (o cualquier otro fallo de carga), degradar al mismo
          // placeholder estático en vez del ícono de imagen rota de Flutter.
          errorBuilder: (context, error, stackTrace) =>
              placeholder(context, width: width, height: height),
        ),
      // Mientras la URL todavía no resolvió (o falló la resolución en sí, no la carga de la
      // imagen): placeholder estático, nunca un spinner animado — evita el problema clásico de
      // `pumpAndSettle()` con animaciones indefinidas en tests (ver `teko_avatar_test.dart` para
      // el mismo criterio de no mockear `Image.network`).
      _ => placeholder(context, width: width, height: height),
    };
  }

  /// Expuesto como método estático (en vez de un closure privado) para poder testear el camino de
  /// `errorBuilder` sin necesidad de mockear una carga de red real.
  static Widget placeholder(
    BuildContext context, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}
