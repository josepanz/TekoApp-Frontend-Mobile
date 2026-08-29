import 'package:pub_semver/pub_semver.dart';

/// Release de GitHub que aplica al ambiente actual — ver
/// `openspec/specs/app-version-update.md`. `version` viene del `tag_name` sin el prefijo `v`,
/// parseado con semver real (nunca comparación de strings, ver `EnvironmentReleaseMatcher`).
class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.version,
    required this.apkDownloadUrl,
    required this.notes,
  });

  final String tagName;
  final Version version;
  final String apkDownloadUrl;
  final String notes;

  bool get hasDownloadableApk => apkDownloadUrl.isNotEmpty;

  /// El único asset instalable directo en Android — ver "Selección del asset a descargar" en la
  /// spec. Si no existe, `apkDownloadUrl` queda vacío y `hasDownloadableApk` es `false`.
  factory AppRelease.fromGitHubJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String;
    final versionString =
        tagName.startsWith('v') ? tagName.substring(1) : tagName;
    final assets = (json['assets'] as List<dynamic>?) ?? [];
    final expectedAssetName = 'tekoapp-mobile-$tagName.apk';
    final apkAsset = assets.cast<Map<String, dynamic>>().where(
          (asset) => asset['name'] == expectedAssetName,
        );

    return AppRelease(
      tagName: tagName,
      version: Version.parse(versionString),
      apkDownloadUrl: apkAsset.isEmpty
          ? ''
          : apkAsset.first['browser_download_url'] as String,
      notes: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'tagName': tagName,
        'version': version.toString(),
        'apkDownloadUrl': apkDownloadUrl,
        'notes': notes,
      };

  factory AppRelease.fromJson(Map<String, dynamic> json) => AppRelease(
        tagName: json['tagName'] as String,
        version: Version.parse(json['version'] as String),
        apkDownloadUrl: json['apkDownloadUrl'] as String,
        notes: json['notes'] as String,
      );
}
