import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/professional_document.dart';
import 'professional_documents_repository_provider.dart';

/// Documentos aprobados y visibles al cliente, por `referenceId` del profesional.
final publicProfessionalDocumentsProvider =
    FutureProvider.autoDispose.family<List<ProfessionalDocument>, String>((
  ref,
  professionalReferenceId,
) {
  return ref
      .watch(professionalDocumentsRepositoryProvider)
      .publicDocuments(professionalReferenceId);
});
