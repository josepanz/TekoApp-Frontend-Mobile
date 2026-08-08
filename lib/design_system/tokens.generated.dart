/// Tokens de marca — portados de `TekoApp-Web/src/design-system/tokens/tokens.json` (rebrand
/// 2026-08-02, formato W3C Design Tokens, colores en OKLCH).
///
/// **Cómo se generó este archivo**: `tokens.json` no tiene un output Dart automatizado todavía
/// (ver `openspec/decisions.md`, sección "Sistema de diseño" — Style Dictionary no tiene un
/// formato Dart registrado en `TekoApp-Web/src/design-system/tokens/build.mjs`). Los valores de
/// acá se calcularon con un script Node de un solo uso que resuelve las referencias de
/// `tokens.json` y convierte cada `oklch(L C H)` a sRGB con el algoritmo de CSS Color Module
/// Level 4 (OKLab → linear sRGB → gamma sRGB) — el mismo cálculo que hace un navegador al
/// renderizar `oklch()`, Dart/Flutter no tiene soporte nativo para ese espacio de color. Se
/// verificó que el resultado reproduce los anclajes de marca documentados en
/// `.claude/rules/design-system.md` (`primary.500` → `#28A745` exacto, `neutral.900` → `#0D1B2A`
/// exacto, `neutral.50` → `#F5F7FA` exacto).
///
/// **Si `tokens.json` cambia, este archivo queda desactualizado** hasta que se regenere a mano
/// (no hay CI que lo valide todavía) — automatizarlo agregando un formato `dart/teko-theme` a
/// `build.mjs` sigue pendiente, documentado como tarea futura, no un olvido.
library;

import 'package:flutter/painting.dart';

class TekoPrimitives {
  TekoPrimitives._();

  // ── primary (verde de marca) ──────────────────────────────────────────────
  static const primary50 = Color(0xFFEDF9ED);
  static const primary100 = Color(0xFFD3F2D5);
  static const primary200 = Color(0xFFAAE2AF);
  static const primary300 = Color(0xFF7CCE86);
  static const primary400 = Color(0xFF4DB860);
  static const primary500 =
      Color(0xFF28A745); // ancla exacta de marca (#28A745)
  static const primary600 =
      Color(0xFF008025); // shade accesible, usado como --primary
  static const primary700 = Color(0xFF006C1F);
  static const primary800 = Color(0xFF005215);
  static const primary900 = Color(0xFF003A0C);

  // ── accent (teal de marca) ─────────────────────────────────────────────────
  static const accent50 = Color(0xFFE7FAF9);
  static const accent100 = Color(0xFFCAF1EF);
  static const accent200 = Color(0xFF9DE3E1);
  static const accent300 = Color(0xFF6FD5D2);
  static const accent400 = Color(0xFF4CCAC7);
  static const accent500 = Color(0xFF19BEBB); // ancla de marca (~#17BEBB)
  static const accent600 = Color(0xFF009B99);
  static const accent700 = Color(0xFF007A79);
  static const accent800 = Color(0xFF005E5D);
  static const accent900 = Color(0xFF004544);

  // ── neutral ────────────────────────────────────────────────────────────────
  static const neutral0 = Color(0xFFFFFFFF);
  static const neutral50 = Color(0xFFF5F7FA); // ancla exacta de marca
  static const neutral100 = Color(0xFFEDF0F4);
  static const neutral200 = Color(0xFFD7DBE0);
  static const neutral300 = Color(0xFFB6BBC1);
  static const neutral400 = Color(0xFF848A91);
  static const neutral500 = Color(0xFF5A6169);
  static const neutral600 = Color(0xFF3D4650);
  static const neutral700 = Color(0xFF222C38);
  static const neutral800 = Color(0xFF192532);
  static const neutral850 = Color(0xFF111E2C);
  static const neutral900 =
      Color(0xFF0D1B2A); // ancla exacta de marca (fondo dark, nunca negro puro)
  static const neutral950 = Color(0xFF040C15);

  // ── semantic (estado — nunca reusar primary/accent para esto) ─────────────
  static const success = Color(0xFF41A452);
  static const warning = Color(0xFF966400);
  static const danger = Color(0xFFDF2225);
  static const info = Color(0xFF008BC7);
}

/// Mapeo semántico claro/oscuro — mismos nombres que `theme.light`/`theme.dark` en `tokens.json`.
class TekoThemeColors {
  const TekoThemeColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.success,
    required this.warning,
    required this.info,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color cardForeground;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color success;
  final Color warning;
  final Color info;
  final Color border;

  static const light = TekoThemeColors(
    background: TekoPrimitives.neutral0,
    foreground: TekoPrimitives.neutral900,
    card: TekoPrimitives.neutral0,
    cardForeground: TekoPrimitives.neutral900,
    primary: TekoPrimitives.primary600,
    primaryForeground: TekoPrimitives.neutral0,
    secondary: TekoPrimitives.neutral100,
    secondaryForeground: TekoPrimitives.neutral900,
    muted: TekoPrimitives.neutral100,
    mutedForeground: TekoPrimitives.neutral500,
    accent: TekoPrimitives.accent500,
    accentForeground: TekoPrimitives.neutral900,
    destructive: TekoPrimitives.danger,
    success: TekoPrimitives.success,
    warning: TekoPrimitives.warning,
    info: TekoPrimitives.info,
    border: TekoPrimitives.neutral200,
  );

  static const dark = TekoThemeColors(
    background: TekoPrimitives.neutral900,
    foreground: TekoPrimitives.neutral50,
    card: TekoPrimitives.neutral850,
    cardForeground: TekoPrimitives.neutral50,
    primary: TekoPrimitives.primary400,
    primaryForeground: TekoPrimitives.neutral950,
    secondary: TekoPrimitives.neutral800,
    secondaryForeground: TekoPrimitives.neutral50,
    muted: TekoPrimitives.neutral800,
    mutedForeground: TekoPrimitives.neutral400,
    accent: TekoPrimitives.accent400,
    accentForeground: TekoPrimitives.neutral950,
    destructive: TekoPrimitives.danger,
    success: TekoPrimitives.success,
    warning: TekoPrimitives.warning,
    info: TekoPrimitives.info,
    border: TekoPrimitives.neutral800,
  );
}
