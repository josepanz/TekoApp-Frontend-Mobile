import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'app_release.dart';
import 'update_check_repository.dart';

final updateCheckRepositoryProvider = Provider<UpdateCheckRepository>((ref) {
  return UpdateCheckRepository();
});

/// `autoDispose`: solo se lee una vez al arrancar (`UpdateCheckGateway`), no necesita mantenerse
/// vivo entre pantallas.
final updateCheckProvider = FutureProvider.autoDispose<AppRelease?>((ref) {
  return ref
      .watch(updateCheckRepositoryProvider)
      .checkForUpdate(Env.environment);
});
