import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/cookie_jar_provider.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(cookieJar: ref.watch(cookieJarProvider));
});
