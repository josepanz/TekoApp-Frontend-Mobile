import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../design_system/tokens.generated.dart';

/// Colores semánticos de estado (éxito/alerta/info) — no tienen equivalente directo en
/// `ColorScheme` de Material 3 (que solo define `error`), así que viajan como `ThemeExtension`
/// (mecanismo oficial de Flutter para esto). Nunca reusar `primary`/`accent` para comunicar
/// estado — ver `.claude/rules/design-system.md`.
@immutable
class TekoSemanticColors extends ThemeExtension<TekoSemanticColors> {
  const TekoSemanticColors({
    required this.success,
    required this.warning,
    required this.info,
  });

  final Color success;
  final Color warning;
  final Color info;

  @override
  TekoSemanticColors copyWith({Color? success, Color? warning, Color? info}) {
    return TekoSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  TekoSemanticColors lerp(TekoSemanticColors? other, double t) {
    if (other is! TekoSemanticColors) return this;
    return TekoSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// `ThemeData` claro/oscuro construido explícitamente desde `tokens.generated.dart` — nunca
/// `ColorScheme.fromSeed` (deriva una paleta algorítmica propia de Material, no reproduce los
/// shades exactos que ya definió el manual de marca en `TekoApp-Web`).
class AppTheme {
  AppTheme._();

  static ThemeData get light =>
      _themeFrom(TekoThemeColors.light, Brightness.light);

  static ThemeData get dark =>
      _themeFrom(TekoThemeColors.dark, Brightness.dark);

  /// Separado de `_themeFrom` para poder testear el mapeo tokens → `ColorScheme` sin tocar
  /// `GoogleFonts` (que intenta resolver la tipografía vía el `AssetBundle`/red — no determinístico
  /// en un test unitario, ver `test/core/theme/app_theme_test.dart`).
  @visibleForTesting
  static ColorScheme colorSchemeFrom(
    TekoThemeColors tokens,
    Brightness brightness,
  ) {
    return ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.primaryForeground,
      secondary: tokens.secondary,
      onSecondary: tokens.secondaryForeground,
      tertiary: tokens.accent,
      onTertiary: tokens.accentForeground,
      error: tokens.destructive,
      onError: TekoPrimitives.neutral0,
      surface: tokens.background,
      onSurface: tokens.foreground,
      surfaceContainerHighest: tokens.muted,
      onSurfaceVariant: tokens.mutedForeground,
      outline: tokens.border,
    );
  }

  static ThemeData _themeFrom(TekoThemeColors tokens, Brightness brightness) {
    final colorScheme = colorSchemeFrom(tokens, brightness);

    final baseTextTheme = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final textTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      cardColor: tokens.card,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      extensions: [
        TekoSemanticColors(
          success: tokens.success,
          warning: tokens.warning,
          info: tokens.info,
        ),
      ],
    );
  }
}
