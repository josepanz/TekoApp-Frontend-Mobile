import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_documents_provider.dart';
import 'professional_documents_repository_provider.dart';

class UploadDocumentController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String professionalDocumentTypeReferenceId,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    DateTime? issuedAt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(professionalDocumentsRepositoryProvider).upload(
            professionalDocumentTypeReferenceId:
                professionalDocumentTypeReferenceId,
            bytes: bytes,
            filename: filename,
            mimeType: mimeType,
            issuedAt: issuedAt,
          );
      ref.invalidate(myDocumentsProvider);
    });
  }
}

final uploadDocumentControllerProvider =
    AsyncNotifierProvider<UploadDocumentController, void>(
  UploadDocumentController.new,
);
