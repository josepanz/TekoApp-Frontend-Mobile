import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tip.dart';
import 'payments_repository_provider.dart';

/// Config activa de propinas (habilitadas/obligatorias/porcentajes sugeridos) — Paraguay-only por
/// ahora, ver `openspec/decisions.md`.
final tipConfigProvider = FutureProvider.autoDispose<TipConfig>((ref) {
  return ref.watch(paymentsRepositoryProvider).fetchTipConfig();
});
