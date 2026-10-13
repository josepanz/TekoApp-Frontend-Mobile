// Parser de JUnit XML de Maestro (`maestro test --format junit`) para el informe QA tipo
// `flujo` de `tool/qa_report.dart`. Dart puro, sin dependencias: Maestro emite un XML plano
// (`<testsuites><testsuite ...><testcase ... status="SUCCESS|ERROR|SKIPPED">`), alcanza con
// regex sobre los tags en vez de sumar el paquete `xml`.

/// Un `<testcase>` de JUnit; en Maestro, un flujo.
class JunitCase {
  JunitCase({
    required this.name,
    required this.status,
    required this.seconds,
    this.message,
  });

  final String name;

  /// `passed`, `failed` o `skipped`.
  final String status;
  final double seconds;

  /// Texto del `<failure>`/`<error>` si lo hubo.
  final String? message;
}

/// Resultado de leer un XML JUnit.
class JunitReport {
  JunitReport({required this.cases, this.device});

  final List<JunitCase> cases;

  /// Atributo `device` del `<testsuite>` (Maestro lo informa), si existe.
  final String? device;

  int get passed => cases.where((c) => c.status == 'passed').length;
  int get failed => cases.where((c) => c.status == 'failed').length;
  int get skipped => cases.where((c) => c.status == 'skipped').length;
  double get seconds => cases.fold(0, (sum, c) => sum + c.seconds);
}

final _tag = RegExp(
  r'<testcase\b([^>]*?)(?:/>|>(.*?)</testcase>)',
  dotAll: true,
);
final _attr = RegExp(r'([\w:-]+)\s*=\s*"([^"]*)"');

String _unescape(String s) => s
    .replaceAllMapped(
      RegExp(r'&#(x?)([0-9a-fA-F]+);'),
      (m) => String.fromCharCode(
        int.parse(m.group(2)!, radix: m.group(1) == 'x' ? 16 : 10),
      ),
    )
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

Map<String, String> _attrs(String raw) => {
      for (final m in _attr.allMatches(raw))
        m.group(1)!: _unescape(m.group(2)!),
    };

String? _bodyMessage(String body, String tag) {
  final m = RegExp(
    '<$tag\\b([^>]*?)(?:/>|>(.*?)</$tag>)',
    dotAll: true,
  ).firstMatch(body);
  if (m == null) return null;
  final fromAttr = _attrs(m.group(1) ?? '')['message'];
  final cdata = RegExp(r'<!\[CDATA\[|\]\]>');
  final text = _unescape((m.group(2) ?? '').replaceAll(cdata, '')).trim();
  final msg = (fromAttr != null && fromAttr.isNotEmpty) ? fromAttr : text;
  return msg.isEmpty ? '(sin mensaje)' : msg;
}

/// Parsea el contenido de un JUnit XML. Estado de cada caso: atributo `status` de Maestro
/// (`SUCCESS` -> passed, `SKIPPED` -> skipped, cualquier otro -> failed) o, si falta, la presencia
/// de `<failure>`/`<error>`/`<skipped>` dentro del `<testcase>`.
JunitReport parseJunit(String xml) {
  final cases = <JunitCase>[];
  for (final m in _tag.allMatches(xml)) {
    final a = _attrs(m.group(1) ?? '');
    final body = m.group(2) ?? '';
    final failure =
        _bodyMessage(body, 'failure') ?? _bodyMessage(body, 'error');
    final skippedTag = RegExp(r'<skipped\b').hasMatch(body);
    final raw = a['status']?.toUpperCase();
    final String status;
    if (raw != null) {
      status = raw == 'SUCCESS'
          ? 'passed'
          : raw == 'SKIPPED'
              ? 'skipped'
              : 'failed';
    } else if (failure != null) {
      status = 'failed';
    } else if (skippedTag) {
      status = 'skipped';
    } else {
      status = 'passed';
    }
    cases.add(
      JunitCase(
        name: a['name'] ?? a['id'] ?? '?',
        status: status,
        seconds: double.tryParse(a['time'] ?? '') ?? 0,
        message: status == 'failed' ? (failure ?? 'status=$raw') : null,
      ),
    );
  }
  final device =
      RegExp(r'<testsuite\b[^>]*?\bdevice="([^"]*)"').firstMatch(xml)?.group(1);
  return JunitReport(
    cases: cases,
    device: device == null ? null : _unescape(device),
  );
}
