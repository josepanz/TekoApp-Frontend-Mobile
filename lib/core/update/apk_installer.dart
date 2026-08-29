import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

/// Dispara el instalador nativo de Android sobre el APK ya descargado — `open_filex` abre el
/// archivo con el handler del sistema para `application/vnd.android.package-archive`, que en
/// Android es el instalador de paquetes (mismo mecanismo que "abrir con"). Requiere
/// `REQUEST_INSTALL_PACKAGES` (Android 8+, pedido en runtime acá).
class ApkInstaller {
  Future<bool> install(String apkFilePath) async {
    final status = await Permission.requestInstallPackages.request();
    if (!status.isGranted) return false;

    final result = await OpenFilex.open(apkFilePath);
    return result.type == ResultType.done;
  }
}
