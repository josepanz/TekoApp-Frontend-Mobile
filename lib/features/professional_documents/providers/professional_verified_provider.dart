import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'professional_documents_repository_provider.dart';

/// `Professionals.verificationStatus == "verified"`, por `referenceId` del profesional.
final professionalVerifiedProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, professionalReferenceId) {
  return ref
      .watch(professionalDocumentsRepositoryProvider)
      .isVerified(professionalReferenceId);
});
