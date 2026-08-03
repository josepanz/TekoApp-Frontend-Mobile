import 'package:flutter/material.dart';

/// ThemeData claro/oscuro — colores de marca copiados TAL CUAL de
/// `TekoApp-Web/src/design-system/tokens/tokens.json` (rebrand 2026-08-02): verde `primary`,
/// teal `accent`, navy `neutral` oscuro. Esto es un placeholder deliberado, no la solución final:
/// `tokens.json` es la única fuente de verdad, y el mecanismo real para generar este archivo
/// desde ahí (un formato adicional de Style Dictionary) está pendiente de decidir en la
/// Fase 0002 (ver `openspec/decisions.md`). Cuando ese generador exista, este archivo se
/// reemplaza por su salida, no se sigue manteniendo a mano.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF28A745);
  static const Color accent = Color(0xFF17BEBB);
  static const Color neutralDark = Color(0xFF0D1B2A);
  static const Color neutralLight = Color(0xFFF5F7FA);

  static ThemeData get light => _themeFrom(Brightness.light);

  static ThemeData get dark => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      secondary: accent,
      surface: isDark ? neutralDark : neutralLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
    );
  }
}
