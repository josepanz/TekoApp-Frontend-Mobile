// Generador del informe de ejecución QA (estándar §3 de QA-DOC-STANDARD.md).
//
// Uso:
//   flutter test --machine --coverage > build/qa/unit.jsonl
//   dart run tool/qa_report.dart build/qa/unit.jsonl unit [coverage/lcov.info]
//
// Lee la salida JSON-por-línea de `flutter test --machine` (eventos start, suite,
// testStart, testDone, error, done) y escribe
// `test/qa/informes/AAAA-MM-DD_<tipo>_<rama-corta>.md`. Las secciones 3 (defectos),
// 4 (desvíos) y 6 (veredicto) quedan con marcadores para completar a mano.
//
// Variables opcionales: QA_COMMAND (comando exacto), QA_EXECUTOR (ejecutor),
// QA_ENV (entorno). Dart puro, sin dependencias externas.
import 'dart:convert';
import 'dart:io';

class _Case {
  _Case(this.name, this.suiteId);
  final String name;
  final int suiteId;
  String result = 'unknown';
  bool skipped = false;
  bool hidden = false;
  final List<String> errors = [];
}

String _norm(String p) => p.replaceAll('\\', '/');

String _rel(String path) {
  var p = _norm(path);
  if (p.startsWith('file:///')) p = p.substring(8);
  final root = '${_norm(Directory.current.path)}/';
  if (p.toLowerCase().startsWith(root.toLowerCase())) {
    return p.substring(root.length);
  }
  final i = p.lastIndexOf('/test/');
  return i >= 0 ? p.substring(i + 1) : p;
}

/// `test/features/auth/widgets/x_test.dart` -> `test/features/auth`;
/// `test/shared/widgets/x_test.dart` -> `test/shared/widgets`;
/// `test/x_test.dart` -> `test`.
String _group(String relPath) {
  final parts = relPath.split('/');
  if (parts.length <= 2) return parts.first;
  if (parts.length > 3) return '${parts[0]}/${parts[1]}/${parts[2]}';
  return '${parts[0]}/${parts[1]}';
}

String _run(String exe, List<String> args) {
  try {
    final r = Process.runSync(exe, args, runInShell: true);
    return (r.stdout as String).trim();
  } on Object {
    return 'n/d';
  }
}

String _pad(int n) => n.toString().padLeft(2, '0');

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Uso: dart run tool/qa_report.dart <salida.jsonl> <tipo> [lcov.info]',
    );
    exit(64);
  }
  final input = File(args[0]);
  final type = args[1];
  final lcovFile = File(args.length > 2 ? args[2] : 'coverage/lcov.info');

  final suites = <int, String>{};
  final cases = <int, _Case>{};
  var maxTime = 0;
  bool? success;

  for (final line in input.readAsLinesSync()) {
    final t = line.trim();
    if (!t.startsWith('{')) continue;
    final Object? decoded;
    try {
      decoded = jsonDecode(t);
    } on FormatException {
      continue;
    }
    if (decoded is! Map<String, dynamic>) continue;
    final time = decoded['time'];
    if (time is int && time > maxTime) maxTime = time;
    switch (decoded['type']) {
      case 'suite':
        final s = decoded['suite'] as Map<String, dynamic>;
        suites[s['id'] as int] = _rel(s['path'] as String);
      case 'testStart':
        final tt = decoded['test'] as Map<String, dynamic>;
        cases[tt['id'] as int] = _Case(
          tt['name'] as String,
          tt['suiteID'] as int,
        );
      case 'testDone':
        final c = cases[decoded['testID'] as int];
        if (c == null) break;
        c.result = decoded['result'] as String;
        c.skipped = decoded['skipped'] == true;
        c.hidden = decoded['hidden'] == true;
      case 'error':
        final c = cases[decoded['testID'] as int];
        final err =
            (decoded['error'] as String).split('\n').take(4).join(' | ');
        c?.errors.add(err);
      case 'done':
        success = decoded['success'] as bool?;
    }
  }

  final real = cases.values
      .where((c) => !c.hidden && !c.name.startsWith('loading '))
      .toList();
  bool passed(_Case c) => c.result == 'success' && !c.skipped;
  bool failedCase(_Case c) => !c.skipped && c.result != 'success';
  final total = real.length;
  final ok = real.where(passed).length;
  final skipped = real.where((c) => c.skipped).length;
  final failed = real.where(failedCase).length;

  final byFile = <String, List<_Case>>{};
  for (final c in real) {
    byFile.putIfAbsent(suites[c.suiteId] ?? '?', () => []).add(c);
  }
  final byGroup = <String, List<_Case>>{};
  byFile.forEach((file, list) {
    byGroup.putIfAbsent(_group(file), () => []).addAll(list);
  });

  String status(List<_Case> l) {
    if (l.any(failedCase)) return 'FALLÓ';
    if (l.isNotEmpty && l.every((c) => c.skipped)) return 'OMITIDO';
    return 'OK';
  }

  // Cobertura de lcov (líneas instrumentadas LF y cubiertas LH).
  var coverage = 'n/d (no se encontró ${_norm(lcovFile.path)})';
  final libCov = <String, List<int>>{};
  if (lcovFile.existsSync()) {
    var lf = 0, lh = 0, fLf = 0, fLh = 0;
    var sf = '?';
    for (final l in lcovFile.readAsLinesSync()) {
      if (l.startsWith('SF:')) {
        sf = _norm(l.substring(3));
        fLf = 0;
        fLh = 0;
      } else if (l.startsWith('LF:')) {
        fLf = int.parse(l.substring(3));
      } else if (l.startsWith('LH:')) {
        fLh = int.parse(l.substring(3));
      } else if (l == 'end_of_record') {
        lf += fLf;
        lh += fLh;
        final p = sf.split('/');
        final key = p.length > 3
            ? '${p[0]}/${p[1]}/${p[2]}'
            : p.length > 2
                ? '${p[0]}/${p[1]}'
                : sf;
        final e = libCov.putIfAbsent(key, () => [0, 0]);
        e[0] += fLf;
        e[1] += fLh;
      }
    }
    coverage = lf == 0
        ? 'n/d (lcov vacío)'
        : '$lh / $lf líneas = ${(lh * 100 / lf).toStringAsFixed(1)} %';
  }

  final now = DateTime.now();
  final date = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
  final stamp = '$date ${_pad(now.hour)}:${_pad(now.minute)}';
  final branch = _run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  final short = branch.contains('/')
      ? branch.substring(branch.indexOf('/') + 1).replaceAll('/', '-')
      : branch;
  final commit = _run('git', ['rev-parse', '--short', 'HEAD']);
  final flutter = RegExp(r'Flutter [0-9.]+')
          .firstMatch(_run('flutter', ['--version']))
          ?.group(0) ??
      'Flutter n/d';
  final repo = _norm(Directory.current.path).split('/').last;
  final env = Platform.environment['QA_ENV'] ??
      'local (${Platform.operatingSystem}), flutter test sobre VM; Dio mockeado';
  final cmd = Platform.environment['QA_COMMAND'] ??
      'flutter test --machine --coverage > ${_norm(input.path)}; '
          'dart run tool/qa_report.dart ${_norm(input.path)} $type';
  final executor = Platform.environment['QA_EXECUTOR'] ?? 'agente (Claude)';
  final secs = (maxTime / 1000).toStringAsFixed(1);
  final global =
      success == null ? 'sin evento done' : (success ? 'success' : 'failure');

  final b = StringBuffer()
    ..writeln('# Informe de ejecución QA — $type — $short')
    ..writeln()
    ..writeln('| Campo | Valor |')
    ..writeln('|---|---|')
    ..writeln('| Fecha y hora | $stamp |')
    ..writeln('| Repo | $repo |')
    ..writeln('| Rama | `$branch` |')
    ..writeln('| Commit | `$commit` (base de la ejecución) |')
    ..writeln('| Entorno | $env; $flutter |')
    ..writeln('| Comando | `$cmd` |')
    ..writeln('| Ejecutor | $executor |')
    ..writeln()
    ..writeln(
      '> Tablas generadas por `tool/qa_report.dart` desde la salida JSON',
    )
    ..writeln(
      '> de `flutter test --machine`. Las secciones 3, 4 y 6 se completan a mano.',
    )
    ..writeln()
    ..writeln('## 1. Resumen')
    ..writeln()
    ..writeln(
      '| Total | Pasaron | Fallaron | Omitidos | Duración | Cobertura |',
    )
    ..writeln('|---:|---:|---:|---:|---:|---|')
    ..writeln('| $total | $ok | $failed | $skipped | ${secs}s | $coverage |')
    ..writeln()
    ..writeln('Resultado global del runner: $global.')
    ..writeln()
    ..writeln('## 2. Resultados por área / feature')
    ..writeln()
    ..writeln(
      '| Área / feature | Archivos | Casos | Pasaron | Fallaron | Omitidos | Estado |',
    )
    ..writeln('|---|---:|---:|---:|---:|---:|---|');
  final groups = byGroup.keys.toList()..sort();
  for (final g in groups) {
    final l = byGroup[g]!;
    final n = byFile.keys.where((f) => _group(f) == g).length;
    b.writeln('| `$g` | $n | ${l.length} | ${l.where(passed).length} '
        '| ${l.where(failedCase).length} | ${l.where((c) => c.skipped).length} '
        '| ${status(l)} |');
  }
  b
    ..writeln()
    ..writeln('### Inventario por archivo de test')
    ..writeln()
    ..writeln('| Archivo | Casos | Pasaron | Fallaron | Omitidos | Estado |')
    ..writeln('|---|---:|---:|---:|---:|---|');
  final files = byFile.keys.toList()..sort();
  for (final f in files) {
    final l = byFile[f]!;
    b.writeln('| `$f` | ${l.length} | ${l.where(passed).length} '
        '| ${l.where(failedCase).length} | ${l.where((c) => c.skipped).length} '
        '| ${status(l)} |');
  }

  final bad = real.where(failedCase).toList();
  final skip = real.where((c) => c.skipped).toList();
  b
    ..writeln()
    ..writeln('### Casos fallidos')
    ..writeln();
  if (bad.isEmpty) {
    b.writeln('Ninguno.');
  } else {
    for (final c in bad) {
      b.writeln('- `${suites[c.suiteId]}` — ${c.name}: '
          '${c.errors.isEmpty ? c.result : c.errors.first}');
    }
  }
  b
    ..writeln()
    ..writeln('### Casos omitidos')
    ..writeln();
  if (skip.isEmpty) {
    b.writeln('Ninguno.');
  } else {
    for (final c in skip) {
      b.writeln('- `${suites[c.suiteId]}` — ${c.name}');
    }
  }

  if (libCov.isNotEmpty) {
    b
      ..writeln()
      ..writeln('### Cobertura por directorio de `lib/`')
      ..writeln()
      ..writeln('| Directorio | Líneas cubiertas | Instrumentadas | % |')
      ..writeln('|---|---:|---:|---:|');
    final keys = libCov.keys.toList()..sort();
    for (final k in keys) {
      final e = libCov[k]!;
      final pct = e[0] == 0 ? '-' : (e[1] * 100 / e[0]).toStringAsFixed(1);
      b.writeln('| `$k` | ${e[1]} | ${e[0]} | $pct |');
    }
  }

  b
    ..writeln()
    ..writeln('## 3. Defectos encontrados')
    ..writeln()
    ..writeln('<!-- MANUAL: DEF-MOB-NNN, severidad, caso, repro, estado -->')
    ..writeln()
    ..writeln('## 4. Desvíos y observaciones')
    ..writeln()
    ..writeln(
      '<!-- MANUAL: flakies, timeouts, entorno, omitidos con motivo -->',
    )
    ..writeln()
    ..writeln('## 5. Evidencia')
    ..writeln()
    ..writeln('- Salida cruda: `${_norm(input.path)}` (no se commitea).')
    ..writeln('- Cobertura: `${_norm(lcovFile.path)}` (no se commitea).')
    ..writeln()
    ..writeln('## 6. Veredicto')
    ..writeln()
    ..writeln(
      '<!-- MANUAL: APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO + criterio -->',
    );

  final dir = Directory('test/qa/informes')..createSync(recursive: true);
  final out = File('${dir.path}/${date}_${type}_$short.md');
  out.writeAsStringSync(b.toString());
  stdout.writeln('Informe escrito en ${_norm(out.path)} '
      '(total=$total ok=$ok fallaron=$failed omitidos=$skipped)');
}
