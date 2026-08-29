import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekoapp_mobile/core/update/apk_actions_providers.dart';
import 'package:tekoapp_mobile/core/update/apk_downloader.dart';
import 'package:tekoapp_mobile/core/update/apk_installer.dart';
import 'package:tekoapp_mobile/core/update/app_release.dart';
import 'package:tekoapp_mobile/core/update/update_available_dialog.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

class _MockApkDownloader extends Mock implements ApkDownloader {}

class _MockApkInstaller extends Mock implements ApkInstaller {}

final _release = AppRelease(
  tagName: 'v1.0.0-develop.31',
  version: Version.parse('1.0.0-develop.31'),
  apkDownloadUrl: 'https://github.com/releases/app.apk',
  notes: 'Notas del release',
);

Future<void> _pumpDialog(
  WidgetTester tester,
  _MockApkDownloader downloader,
  _MockApkInstaller installer,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apkDownloaderProvider.overrideWithValue(downloader),
        apkInstallerProvider.overrideWithValue(installer),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showUpdateAvailableDialog(context, _release),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  late _MockApkDownloader downloader;
  late _MockApkInstaller installer;

  setUp(() {
    downloader = _MockApkDownloader();
    installer = _MockApkInstaller();
  });

  testWidgets('tap en Cancelar cierra el modal sin descargar nada', (
    tester,
  ) async {
    // Arrange
    await _pumpDialog(tester, downloader, installer);
    expect(find.text('Actualización disponible'), findsOneWidget);

    // Act
    await tester.tap(find.byKey(const Key('update_dialog_cancel_button')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('Actualización disponible'), findsNothing);
    verifyNever(
      () => downloader.download(any(), onProgress: any(named: 'onProgress')),
    );
  });

  testWidgets(
    'tap en Actualizar descarga el APK y dispara el instalador',
    (tester) async {
      // Arrange
      when(
        () => downloader.download(any(), onProgress: any(named: 'onProgress')),
      ).thenAnswer((_) async => '/cache/update.apk');
      when(() => installer.install(any())).thenAnswer((_) async => true);
      await _pumpDialog(tester, downloader, installer);

      // Act
      await tester.tap(find.byKey(const Key('update_dialog_update_button')));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => downloader.download(
          _release.apkDownloadUrl,
          onProgress: any(named: 'onProgress'),
        ),
      ).called(1);
      verify(() => installer.install('/cache/update.apk')).called(1);
      expect(find.text('Actualización disponible'), findsNothing);
    },
  );

  testWidgets(
    'muestra un error claro si la descarga falla, sin cerrar el modal',
    (tester) async {
      // Arrange
      when(
        () => downloader.download(any(), onProgress: any(named: 'onProgress')),
      ).thenThrow(Exception('sin conexión'));
      await _pumpDialog(tester, downloader, installer);

      // Act
      await tester.tap(find.byKey(const Key('update_dialog_update_button')));
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('No se pudo descargar la actualización — intentá de nuevo'),
        findsOneWidget,
      );
      expect(find.text('Actualización disponible'), findsOneWidget);
    },
  );
}
