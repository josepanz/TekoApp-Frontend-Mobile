import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/design_system/tokens.generated.dart';

/// No valida la conversión OKLCH->sRGB en sí (eso se hizo una vez con un script Node, ver el
/// comentario de cabecera de `tokens.generated.dart`) — valida que los anclajes de marca ya
/// documentados en `.claude/rules/design-system.md` siguen siendo exactos en este archivo, para
/// detectar un copy-paste roto si alguien lo regenera a mano en el futuro.
void main() {
  test('primary.500 reproduce el verde de marca exacto (#28A745)', () {
    expect(TekoPrimitives.primary500, const Color(0xFF28A745));
  });

  test('neutral.900 reproduce el navy de marca exacto (#0D1B2A)', () {
    expect(TekoPrimitives.neutral900, const Color(0xFF0D1B2A));
  });

  test('neutral.50 reproduce el gris claro de marca exacto (#F5F7FA)', () {
    expect(TekoPrimitives.neutral50, const Color(0xFFF5F7FA));
  });

  test(
      'el tema claro usa el shade accesible (600) como primary, no el 500 crudo',
      () {
    expect(TekoThemeColors.light.primary, TekoPrimitives.primary600);
  });

  test('el tema oscuro nunca usa negro puro de fondo', () {
    expect(TekoThemeColors.dark.background, isNot(const Color(0xFF000000)));
    expect(TekoThemeColors.dark.background, TekoPrimitives.neutral900);
  });
}
