import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'professional_documents_repository_provider.dart';

/// Resuelve la URL presignada de un documento a partir de su key de S3 — `autoDispose`, nunca
/// cacheada más allá del widget que la muestra.
final professionalDocumentFileUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, key) {
  return ref
      .watch(professionalDocumentsRepositoryProvider)
      .resolveFileUrl(key);
});
