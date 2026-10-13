// Suite: parser de JUnit XML de Maestro (tool/qa_junit.dart) usado por el informe QA tipo `flujo`
// Casos: CP-MOB-CAT-004 (ver test/qa/casos/CP-CAT.md)
// Tipo: unitaria   Prioridad: P2
// Precondiciones: ninguna (XML de ejemplo en memoria, con la forma de `maestro test --format junit`)
// Trazabilidad: plan maestro E2E W1, QA-DOC-STANDARD §3 (Maestro: --format junit)
import 'package:flutter_test/flutter_test.dart';

import '../../tool/qa_junit.dart';

const _sample = '''<?xml version='1.0' encoding='UTF-8'?>
<testsuites>
  <testsuite name="Test Suite" device="emulator-5554" tests="4" failures="1" time="52.40">
    <testcase id="m1-login-ok" name="m1-login-ok" classname="m1-login-ok" time="12.30" status="SUCCESS"/>
    <testcase id="m1-login-invalido" name="m1-login-invalido" classname="m1-login-invalido" time="9.10" status="ERROR">
      <failure>Assertion is false: "Email o contrase&#241;a incorrectos" is visible &amp; no aparece</failure>
    </testcase>
    <testcase id="m2-catalogos" name="m2-catalogos" classname="m2-catalogos" time="20.00" status="SUCCESS"></testcase>
    <testcase id="m2-catalogos-sin-red" name="m2-catalogos-sin-red" classname="m2-catalogos-sin-red" time="11.00" status="SKIPPED"/>
  </testsuite>
</testsuites>
''';

void main() {
  group('parseJunit', () {
    test('cuenta flujos por estado y suma la duracion', () {
      // Arrange & Act
      final report = parseJunit(_sample);

      // Assert
      expect(report.cases, hasLength(4));
      expect(report.passed, 2);
      expect(report.failed, 1);
      expect(report.skipped, 1);
      expect(report.seconds, closeTo(52.4, 0.001));
      expect(report.device, 'emulator-5554');
    });

    test('extrae nombre y mensaje del fallo, decodificando entidades', () {
      // Arrange & Act
      final failed = parseJunit(_sample).cases.firstWhere(
            (c) => c.status == 'failed',
          );

      // Assert
      expect(failed.name, 'm1-login-invalido');
      expect(failed.message, contains('is visible & no aparece'));
    });

    test('sin atributo status infiere el estado por <failure>/<skipped>', () {
      // Arrange
      const xml = '<testsuite><testcase name="a" time="1"/>'
          '<testcase name="b" time="2"><failure message="boom"/></testcase>'
          '<testcase name="c"><skipped/></testcase></testsuite>';

      // Act
      final cases = parseJunit(xml).cases;

      // Assert
      expect(cases.map((c) => c.status), ['passed', 'failed', 'skipped']);
      expect(cases[1].message, 'boom');
    });

    test('XML sin testcases devuelve un reporte vacio', () {
      // Arrange & Act
      final report = parseJunit('<testsuites/>');

      // Assert
      expect(report.cases, isEmpty);
      expect(report.device, isNull);
    });
  });
}
