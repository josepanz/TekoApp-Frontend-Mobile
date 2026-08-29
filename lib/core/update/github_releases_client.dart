import 'package:dio/dio.dart';

/// Pega DIRECTO a `api.github.com` — repo público, sin autenticación (ver "Fuente de datos" en
/// `openspec/specs/app-version-update.md`). Nunca reusa `core/api_client` (ese cliente apunta al
/// backend propio, con interceptors de Bearer/refresh que no aplican acá).
class GitHubReleasesClient {
  GitHubReleasesClient({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://api.github.com'));

  final Dio _dio;

  static const _repo = 'josepanz/TekoApp-Frontend-Mobile';

  /// NUNCA `/releases/latest` — excluye prerelease, y `qa`/`develop` están marcados
  /// `prerelease: true` (ver spec). Se filtra client-side por ambiente en
  /// `EnvironmentReleaseMatcher`.
  Future<List<dynamic>> fetchReleases() async {
    final response = await _dio.get<List<dynamic>>(
      '/repos/$_repo/releases',
      queryParameters: {'per_page': 100},
    );
    return response.data ?? [];
  }
}
