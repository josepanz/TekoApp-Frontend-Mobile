import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekoapp_mobile/core/update/github_releases_client.dart';
import 'package:tekoapp_mobile/core/update/update_check_repository.dart';

class _MockGitHubReleasesClient extends Mock implements GitHubReleasesClient {}

Map<String, dynamic> _release(String tagName) {
  return {
    'tag_name': tagName,
    'draft': false,
    'body': '',
    'assets': [
      {
        'name': 'tekoapp-mobile-$tagName.apk',
        'browser_download_url': 'https://github.com/releases/$tagName/app.apk',
      },
    ],
  };
}

void _setInstalledVersion(String version) {
  PackageInfo.setMockInitialValues(
    appName: 'TekoApp',
    packageName: 'py.com.tekoapp.mobile',
    version: version,
    buildNumber: '1',
    buildSignature: '',
  );
}

void main() {
  late _MockGitHubReleasesClient client;
  late UpdateCheckRepository repository;

  setUp(() {
    client = _MockGitHubReleasesClient();
    SharedPreferences.setMockInitialValues({});
    repository = UpdateCheckRepository(client: client);
  });

  test('devuelve el release cuando hay una versión más nueva para el ambiente', () async {
    // Arrange
    _setInstalledVersion('1.0.0-develop.9');
    when(() => client.fetchReleases()).thenAnswer(
      (_) async => [_release('v1.0.0-develop.31')],
    );

    // Act
    final release = await repository.checkForUpdate('dev');

    // Assert
    expect(release?.tagName, 'v1.0.0-develop.31');
  });

  test(
    'compara semver real: 1.0.0-develop.10 SÍ es más nuevo que 1.0.0-develop.9',
    () async {
      // Arrange
      _setInstalledVersion('1.0.0-develop.9');
      when(() => client.fetchReleases()).thenAnswer(
        (_) async => [_release('v1.0.0-develop.10')],
      );

      // Act
      final release = await repository.checkForUpdate('dev');

      // Assert — una comparación de strings ingenua diría "9" > "10" y fallaría este caso
      expect(release, isNotNull);
    },
  );

  test('devuelve null cuando la versión instalada ya es la más nueva', () async {
    // Arrange
    _setInstalledVersion('1.0.0-develop.31');
    when(() => client.fetchReleases()).thenAnswer(
      (_) async => [_release('v1.0.0-develop.31')],
    );

    // Act
    final release = await repository.checkForUpdate('dev');

    // Assert
    expect(release, isNull);
  });

  test('fail-open: sin conexión o API caída, devuelve null sin lanzar', () async {
    // Arrange
    _setInstalledVersion('1.0.0-develop.1');
    when(() => client.fetchReleases()).thenThrow(Exception('network down'));

    // Act
    final release = await repository.checkForUpdate('dev');

    // Assert
    expect(release, isNull);
  });

  test(
    'cachea el resultado del fetch — una segunda llamada dentro del TTL no vuelve a pegarle a GitHub',
    () async {
      // Arrange
      _setInstalledVersion('1.0.0-develop.9');
      when(() => client.fetchReleases()).thenAnswer(
        (_) async => [_release('v1.0.0-develop.31')],
      );

      // Act
      await repository.checkForUpdate('dev');
      await repository.checkForUpdate('dev');

      // Assert
      verify(() => client.fetchReleases()).called(1);
    },
  );
}
