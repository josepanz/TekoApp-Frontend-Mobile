import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api_client/api_client.dart';
import '../models/profile_failure.dart';

/// Autoedición de perfil (`PUT /auth/me`) y avatar (`POST /uploads/avatar`) — ambos requieren
/// sesión (Bearer, adjuntado solo por `BearerAuthInterceptor` de `ApiClient`, ningún Basic Auth
/// de cliente acá). Ver `openspec/project.md` sobre `avatarKey` (persistido) vs `avatarUrl`
/// (resuelta, nunca persistida).
class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Mismo límite que `TekoApp-Backend/src/api/uploads/const/uploads.const.ts` (`MAX_FILE_SIZE`).
  static const maxAvatarBytes = 5 * 1024 * 1024;

  /// Mismos tipos que acepta `uploadsService.uploadAvatar` (subconjunto de `ALLOWED_MIME_TYPES`
  /// del backend — ahí también entran PDF/Word, que no aplican a un avatar).
  static const allowedAvatarMimeTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
  };

  /// Campos `null` se omiten del body — el backend solo actualiza lo que se manda
  /// (`UpdateMeRequestDTO`, todos los campos opcionales).
  Future<void> updateMe({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? avatarKey,
  }) async {
    try {
      await _apiClient.raw.put<Map<String, dynamic>>(
        '/auth/me',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (avatarKey != null) 'avatarKey': avatarKey,
        },
      );
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// Sube el archivo y devuelve la `key` de S3 — el caller todavía tiene que persistirla vía
  /// `updateMe(avatarKey: key)` (son 2 pasos separados en el backend, ver
  /// `openspec/project.md`).
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    if (bytes.length > maxAvatarBytes) {
      throw const AvatarTooLargeFailure();
    }
    if (!allowedAvatarMimeTypes.contains(mimeType)) {
      throw const AvatarUnsupportedTypeFailure();
    }

    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/uploads/avatar',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        }),
      );
      return response.data!['key'] as String;
    } on DioException {
      throw const AvatarUploadServiceFailure();
    }
  }

  ProfileFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return const ProfileValidationFailure();
    }
    return const ProfileServiceUnavailableFailure();
  }
}
