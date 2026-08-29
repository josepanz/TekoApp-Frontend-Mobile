import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/my_document_status.dart';
import 'professional_documents_repository_provider.dart';

/// "Mis documentos" — online-only, `autoDispose` (ver `openspec/decisions.md`).
final myDocumentsProvider = FutureProvider.autoDispose<List<MyDocumentStatus>>((
  ref,
) {
  return ref.watch(professionalDocumentsRepositoryProvider).myDocuments();
});
