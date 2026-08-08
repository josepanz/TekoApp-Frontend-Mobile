import 'package:flutter/material.dart';

enum TekoAvatarSize { sm, md, lg }

/// Avatar circular — equivalente a `TekoApp-Web/src/components/ui/avatar.tsx`. Recibe siempre la
/// `avatarUrl` ya resuelta (nunca la `avatarKey` cruda, ver `.claude/rules/auth.md`) — si es
/// `null`/falla la carga, cae a iniciales sobre `colorScheme.secondary`.
class TekoAvatar extends StatelessWidget {
  const TekoAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = TekoAvatarSize.md,
    this.semanticLabel,
  });

  final String name;
  final String? avatarUrl;
  final TekoAvatarSize size;
  final String? semanticLabel;

  double get _diameter => switch (size) {
        TekoAvatarSize.sm => 32,
        TekoAvatarSize.md => 48,
        TekoAvatarSize.lg => 96,
      };

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diameter = _diameter;

    return Semantics(
      label: semanticLabel ?? 'Avatar de $name',
      image: true,
      container: true,
      excludeSemantics: true,
      child: ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: avatarUrl != null
              ? Image.network(
                  avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _fallback(colorScheme, diameter),
                )
              : _fallback(colorScheme, diameter),
        ),
      ),
    );
  }

  Widget _fallback(ColorScheme colorScheme, double diameter) {
    return Container(
      color: colorScheme.secondary,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: colorScheme.onSecondary,
          fontWeight: FontWeight.w600,
          fontSize: diameter * 0.35,
        ),
      ),
    );
  }
}
