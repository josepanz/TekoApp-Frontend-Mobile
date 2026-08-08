import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/professional_profile.dart';
import '../models/professional_profile_failure.dart';

/// Perfil profesional propio (`/professionals/me`, `/professionals`) — todo el árbol de
/// `/professionals` exige JWT (ya cubierto por `BearerAuthInterceptor`, ver
/// `openspec/decisions.md`).
class ProfessionalProfileRepository {
  ProfessionalProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  /// `null` si el usuario todavía no activó su perfil profesional — un 404 acá es un estado de
  /// negocio normal (ver `ProfessionalsController.getMe`), nunca una excepción.
  Future<ProfessionalProfile?> fetchMe() async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/professionals/me',
      );
      return ProfessionalProfile.fromJson(response.data!);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      throw const ProfessionalProfileServiceUnavailableFailure();
    }
  }

  Future<ProfessionalProfile> register({
    required int categoryId,
    required String description,
    required double hourlyRate,
    double? fixedRate,
    List<String>? skills,
    int? yearsOfExperience,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/professionals',
        data: {
          'categoryId': categoryId,
          'description': description,
          'hourlyRate': hourlyRate,
          if (fixedRate != null) 'fixedRate': fixedRate,
          if (skills != null) 'skills': skills,
          if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
        },
      );
      return ProfessionalProfile.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  ProfessionalProfileFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return const ProfessionalProfileValidationFailure();
    }
    return const ProfessionalProfileServiceUnavailableFailure();
  }
}
