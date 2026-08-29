import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'contracts_repository_provider.dart';

/// URL presignada al PDF firmado — se resuelve fresca en cada pedido (mismo criterio que
/// `professionalDocumentFileUrlProvider`, nunca se cachea una URL presignada más allá del pedido
/// puntual).
final contractPdfUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, contractReferenceId) {
  return ref.watch(contractsRepositoryProvider).fetchPdfUrl(contractReferenceId);
});
