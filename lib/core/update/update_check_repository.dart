import 'dart:convert';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_release.dart';
import 'environment_release_matcher.dart';
import 'github_releases_client.dart';

const _lastFetchAtPrefsKey = 'update_check_last_fetch_at';
const _cachedReleasePrefsKey = 'update_check_cached_release';

/// TTL del caché de la llamada a GitHub — no del resultado de la comparación de versión (esa
/// siempre se recalcula fresca contra `PackageInfo.fromPlatform()`). Protege el rate limit sin
/// auth de la API (60 req/hora/IP, ver spec).
const _cacheTtl = Duration(hours: 6);

/// Orquesta el chequeo completo: matchear el release del ambiente (con caché) + comparar semver
/// real contra la versión instalada — ver `openspec/specs/app-version-update.md`.
class UpdateCheckRepository {
  UpdateCheckRepository({GitHubReleasesClient? client})
      : _client = client ?? GitHubReleasesClient();

  final GitHubReleasesClient _client;

  /// `null` = sin actualización disponible (o chequeo fallido — fail-open, nunca rompe el
  /// arranque de la app).
  Future<AppRelease?> checkForUpdate(String environment) async {
    final matched = await _matchedReleaseForEnvironment(environment);
    if (matched == null) return null;

    final installedVersion = Version.parse(
      (await PackageInfo.fromPlatform()).version,
    );
    return matched.version > installedVersion ? matched : null;
  }

  Future<AppRelease?> _matchedReleaseForEnvironment(String environment) async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchAtRaw = prefs.getString(_lastFetchAtPrefsKey);
    final lastFetchAt =
        lastFetchAtRaw != null ? DateTime.tryParse(lastFetchAtRaw) : null;
    final isCacheFresh = lastFetchAt != null &&
        DateTime.now().difference(lastFetchAt) < _cacheTtl;

    if (isCacheFresh) {
      final cachedJson = prefs.getString(_cachedReleasePrefsKey);
      if (cachedJson == null) return null;
      return AppRelease.fromJson(
        jsonDecode(cachedJson) as Map<String, dynamic>,
      );
    }

    try {
      final rawReleases = await _client.fetchReleases();
      final matched = EnvironmentReleaseMatcher.matchLatest(
        rawReleases,
        environment,
      );
      await prefs.setString(
        _lastFetchAtPrefsKey,
        DateTime.now().toIso8601String(),
      );
      if (matched != null) {
        await prefs.setString(
          _cachedReleasePrefsKey,
          jsonEncode(matched.toJson()),
        );
      } else {
        await prefs.remove(_cachedReleasePrefsKey);
      }
      return matched;
    } catch (_) {
      // Sin conexión / API de GitHub caída: fail-open, no cachear el fallo (se reintenta en el
      // próximo chequeo en vez de quedar "sin actualización" hasta que expire un TTL de error).
      return null;
    }
  }
}
