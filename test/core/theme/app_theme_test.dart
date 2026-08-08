import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/theme/app_theme.dart';
import 'package:tekoapp_mobile/design_system/tokens.generated.dart';

/// No instancia `AppTheme.light`/`.dark` directamente — esos getters arman el `textTheme` vía
/// `GoogleFonts`, que intenta resolver la tipografía por `AssetBundle`/red (no determinístico en
/// un test unitario headless, sin acceso de red confiable). Se testea `colorSchemeFrom` (el
/// mapeo tokens → `ColorScheme`, que es la parte que de verdad hay que validar acá) directo, y la
/// carga real de Poppins queda para verificación visual (José corriendo la app).
void main() {
  test('el ColorScheme claro usa los colores de marca de tokens.generated.dart',
      () {
    final colorScheme = AppTheme.colorSchemeFrom(
      TekoThemeColors.light,
      Brightness.light,
    );

    expect(colorScheme.brightness, Brightness.light);
    expect(colorScheme.primary, TekoThemeColors.light.primary);
    expect(colorScheme.tertiary, TekoThemeColors.light.accent);
    expect(colorScheme.surface, TekoThemeColors.light.background);
  });

  test(
      'el ColorScheme oscuro usa los colores de marca de tokens.generated.dart',
      () {
    final colorScheme = AppTheme.colorSchemeFrom(
      TekoThemeColors.dark,
      Brightness.dark,
    );

    expect(colorScheme.brightness, Brightness.dark);
    expect(colorScheme.primary, TekoThemeColors.dark.primary);
    expect(colorScheme.surface, TekoThemeColors.dark.background);
    expect(colorScheme.surface, isNot(const Color(0xFF000000)));
  });

  test(
    'TekoSemanticColors expone success/warning/info de tokens.generated.dart',
    () {
      const extension = TekoSemanticColors(
        success: TekoPrimitives.success,
        warning: TekoPrimitives.warning,
        info: TekoPrimitives.info,
      );

      expect(extension.success, TekoPrimitives.success);
      expect(extension.warning, TekoPrimitives.warning);
      expect(extension.info, TekoPrimitives.info);
    },
  );

  test(
    'TekoSemanticColors.lerp interpola entre dos instancias sin errores',
    () {
      const target = Color(0xFFFF0000);
      const a = TekoSemanticColors(
        success: Color(0xFF00FF00),
        warning: Color(0xFFFFA500),
        info: Color(0xFF0000FF),
      );
      const b = TekoSemanticColors(
        success: target,
        warning: target,
        info: target,
      );

      final result = a.lerp(b, 1.0);

      expect(result.success, target);
      expect(result.warning, target);
      expect(result.info, target);
    },
  );

  test('TekoSemanticColors.lerp devuelve this si el otro no es del mismo tipo',
      () {
    const a = TekoSemanticColors(
      success: Color(0xFF00FF00),
      warning: Color(0xFFFFA500),
      info: Color(0xFF0000FF),
    );

    expect(a.lerp(null, 0.5), same(a));
  });
}
