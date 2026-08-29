import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/legal_consents/providers/consent_required_bridge_provider.dart';
import '../auth/cookie_jar_provider.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final bridge = ref.watch(consentRequiredBridgeProvider);
  return ApiClient(
    cookieJar: ref.watch(cookieJarProvider),
    onConsentRequired: bridge.requestConsentAndWait,
  );
});
