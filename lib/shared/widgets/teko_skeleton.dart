import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

enum _TekoSkeletonVariant { line, card, list }

/// Placeholder de carga con shimmer liviano (sin dependencias). Variantes: [TekoSkeleton.line],
/// [TekoSkeleton.card] y [TekoSkeleton.list]. Usa los tokens del tema (`surfaceContainerHighest`
/// como base, `surface` como brillo), por lo que respeta dark mode, y deja de animarse cuando el
/// sistema pide reducir movimiento (`MediaQuery.disableAnimations`). El subárbol se excluye de la
/// semántica y se anuncia como un único "Cargando".
class TekoSkeleton extends StatefulWidget {
  const TekoSkeleton.line({
    super.key,
    this.width,
    this.height = 16,
  })  : _variant = _TekoSkeletonVariant.line,
        itemCount = 1;

  const TekoSkeleton.card({
    super.key,
    this.height = 96,
  })  : _variant = _TekoSkeletonVariant.card,
        width = null,
        itemCount = 1;

  const TekoSkeleton.list({
    super.key,
    this.itemCount = 5,
    this.height = 96,
  })  : _variant = _TekoSkeletonVariant.list,
        width = null;

  final _TekoSkeletonVariant _variant;
  final double? width;
  final double height;
  final int itemCount;

  @override
  State<TekoSkeleton> createState() => _TekoSkeletonState();
}

class _TekoSkeletonState extends State<TekoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _block(double? width, double height, double radius) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final base = colorScheme.surfaceContainerHighest;
        final highlight =
            Color.alphaBlend(colorScheme.surface.withValues(alpha: 0.6), base);
        final t = _controller.value;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 3 * t - 1, 0),
              end: Alignment(1.0 + 3 * t - 1, 0),
              colors: [base, highlight, base],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }

  Widget _card() => Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _block(160, 14, 4),
            const SizedBox(height: 10),
            _block(null, 12, 4),
            const SizedBox(height: 6),
            _block(120, 12, 4),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final content = switch (widget._variant) {
      _TekoSkeletonVariant.line => _block(widget.width, widget.height, 4),
      _TekoSkeletonVariant.card => _card(),
      _TekoSkeletonVariant.list => ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: widget.itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => _card(),
        ),
    };
    return Semantics(
      label: AppLocalizations.of(context)?.skeletonLoadingLabel ?? 'Cargando',
      container: true,
      excludeSemantics: true,
      child: content,
    );
  }
}
