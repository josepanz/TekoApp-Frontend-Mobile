import 'app_release.dart';

/// Regla central: nunca cruzar ambientes — ver
/// `openspec/specs/app-version-update.md`, "Regla central: nunca cruzar ambientes". Patrones
/// verificados contra los tags reales que emite `.releaserc.json`/`release.yml`.
class EnvironmentReleaseMatcher {
  EnvironmentReleaseMatcher._();

  static final Map<String, RegExp> _tagPatterns = {
    'dev': RegExp(r'^v\d+\.\d+\.\d+-develop\.\d+$'),
    'qa': RegExp(r'^v\d+\.\d+\.\d+-qa\.\d+$'),
    'prod': RegExp(r'^v\d+\.\d+\.\d+$'),
  };

  /// `rawReleases` ya viene ordenada por fecha de creación descendente (orden nativo de la API de
  /// GitHub) — se toma el primer match. `null` si ninguno matchea el patrón del ambiente, es
  /// `draft`, o no tiene el asset `.apk` esperado (fail-open, ver spec).
  static AppRelease? matchLatest(List<dynamic> rawReleases, String environment) {
    final pattern = _tagPatterns[environment];
    if (pattern == null) return null;

    for (final raw in rawReleases) {
      final json = raw as Map<String, dynamic>;
      if (json['draft'] == true) continue;

      final tagName = json['tag_name'] as String?;
      if (tagName == null || !pattern.hasMatch(tagName)) continue;

      final release = AppRelease.fromGitHubJson(json);
      if (!release.hasDownloadableApk) continue;

      return release;
    }
    return null;
  }
}
