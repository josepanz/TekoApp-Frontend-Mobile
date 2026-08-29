import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/legal_document_version.dart';
import 'legal_consents_repository_provider.dart';

final pendingConsentsProvider =
    FutureProvider.autoDispose<List<LegalDocumentVersion>>((ref) async {
  return ref.watch(legalConsentsRepositoryProvider).fetchPendingConsents();
});
