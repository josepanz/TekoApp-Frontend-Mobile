import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/core/update/environment_release_matcher.dart';

Map<String, dynamic> _release({
  required String tagName,
  bool draft = false,
  bool withApkAsset = true,
}) {
  return {
    'tag_name': tagName,
    'draft': draft,
    'body': 'Notas del release',
    'assets': withApkAsset
        ? [
            {
              'name': 'tekoapp-mobile-$tagName.apk',
              'browser_download_url':
                  'https://github.com/releases/download/$tagName/app.apk',
            },
          ]
        : <Map<String, dynamic>>[],
  };
}

void main() {
  test('elige el release más reciente que matchea el patrón de dev', () {
    // Arrange
    final releases = [
      _release(tagName: 'v1.0.0-develop.31'),
      _release(tagName: 'v1.0.0-develop.30'),
    ];

    // Act
    final match = EnvironmentReleaseMatcher.matchLatest(releases, 'dev');

    // Assert
    expect(match?.tagName, 'v1.0.0-develop.31');
  });

  test('nunca cruza ambientes — un build dev ignora tags de qa y prod', () {
    // Arrange
    final releases = [
      _release(tagName: 'v1.0.0'), // prod
      _release(tagName: 'v1.0.0-qa.2'), // qa
      _release(tagName: 'v1.0.0-develop.9'), // dev — el único válido
    ];

    // Act
    final match = EnvironmentReleaseMatcher.matchLatest(releases, 'dev');

    // Assert
    expect(match?.tagName, 'v1.0.0-develop.9');
  });

  test('ignora releases sin el asset APK esperado', () {
    // Arrange
    final releases = [
      _release(tagName: 'v1.0.0-develop.10', withApkAsset: false),
      _release(tagName: 'v1.0.0-develop.9'),
    ];

    // Act
    final match = EnvironmentReleaseMatcher.matchLatest(releases, 'dev');

    // Assert
    expect(match?.tagName, 'v1.0.0-develop.9');
  });

  test('ignora releases en estado draft', () {
    // Arrange
    final releases = [
      _release(tagName: 'v1.0.0-develop.10', draft: true),
      _release(tagName: 'v1.0.0-develop.9'),
    ];

    // Act
    final match = EnvironmentReleaseMatcher.matchLatest(releases, 'dev');

    // Assert
    expect(match?.tagName, 'v1.0.0-develop.9');
  });

  test('devuelve null cuando ningún release matchea el ambiente', () {
    // Arrange
    final releases = [_release(tagName: 'v1.0.0-qa.5')];

    // Act
    final match = EnvironmentReleaseMatcher.matchLatest(releases, 'dev');

    // Assert
    expect(match, isNull);
  });

  test('el release de prod matchea solo tags sin sufijo de prerelease', () {
    // Arrange
    final releases = [
      _release(tagName: 'v1.0.0-develop.31'),
      _release(tagName: 'v1.0.0'),
    ];

    // Act
    final match = EnvironmentReleaseMatcher.matchLatest(releases, 'prod');

    // Assert
    expect(match?.tagName, 'v1.0.0');
  });
}
