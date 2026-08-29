import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client/api_client_provider.dart';
import '../data/professional_documents_repository.dart';

final professionalDocumentsRepositoryProvider =
    Provider<ProfessionalDocumentsRepository>((ref) {
  return ProfessionalDocumentsRepository(ref.watch(apiClientProvider));
});
