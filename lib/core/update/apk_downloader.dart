import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Descarga el APK a un directorio de CACHÉ propio de la app (`getApplicationCacheDirectory`,
/// mapea a `context.cacheDir` en Android) — `open_filex` (usado en `ApkInstaller`) trae su propio
/// `FileProvider` con un `cache-path` que ya cubre este directorio, así que no hace falta declarar
/// uno propio en el manifest (verificado leyendo el manifest/paths que empaqueta el plugin, antes
/// de agregar uno duplicado — ver `openspec/decisions.md`).
class ApkDownloader {
  ApkDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String> download(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await getApplicationCacheDirectory();
    final filePath = '${dir.path}/update.apk';
    await _dio.download(url, filePath, onReceiveProgress: onProgress);
    return filePath;
  }
}
