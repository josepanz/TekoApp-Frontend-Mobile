import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'apk_downloader.dart';
import 'apk_installer.dart';

final apkDownloaderProvider = Provider<ApkDownloader>((ref) => ApkDownloader());
final apkInstallerProvider = Provider<ApkInstaller>((ref) => ApkInstaller());
