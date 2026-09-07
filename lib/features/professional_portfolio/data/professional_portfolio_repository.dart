import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api_client/api_client.dart';
import '../models/portfolio_failure.dart';
import '../models/portfolio_item.dart';

/// `/professionals/me/portfolio`, `/professionals/:referenceId/portfolio/public` — todo el árbol
/// exige JWT (ya cubierto por `BearerAuthInterceptor`). Ver
/// `TekoApp-Backend/openspec/specs/professional-onboarding-and-portfolio.md`, Fase 4.
///
/// Mismo criterio que `professional_documents`: el archivo viaja en el mismo POST que crea la
/// foto (multipart directo), el backend reusa `modules/storage` internamente.
class ProfessionalPortfolioRepository {
  ProfessionalPortfolioRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PortfolioItem>> myPortfolio() async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/professionals/me/portfolio',
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<List<PortfolioItem>> publicPortfolio(
    String professionalReferenceId,
  ) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/professionals/$professionalReferenceId/portfolio/public',
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// `fileKey` es una key de S3, no una URL — resuelve una URL presignada fresca, nunca
  /// persistida más allá de la pantalla actual (mismo criterio que `avatarKey`/`avatarUrl`).
  Future<String> resolveFileUrl(String key) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/uploads/presigned-url',
        queryParameters: {'key': key},
      );
      return response.data!['url'] as String;
    } on DioException {
      throw const PortfolioServiceUnavailableFailure();
    }
  }

  Future<PortfolioItem> upload({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? caption,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/professionals/me/portfolio',
        data: FormData.fromMap({
          if (caption != null && caption.isNotEmpty) 'caption': caption,
          'file': MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        }),
      );
      return PortfolioItem.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<PortfolioItem> update(
    String referenceId, {
    String? caption,
    int? sortOrder,
    bool? isVisible,
  }) async {
    try {
      final response = await _apiClient.raw.patch<Map<String, dynamic>>(
        '/professionals/me/portfolio/$referenceId',
        data: {
          if (caption != null) 'caption': caption,
          if (sortOrder != null) 'sortOrder': sortOrder,
          if (isVisible != null) 'isVisible': isVisible,
        },
      );
      return PortfolioItem.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<void> delete(String referenceId) async {
    try {
      await _apiClient.raw.delete<void>(
        '/professionals/me/portfolio/$referenceId',
      );
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  PortfolioFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final backendMessage = _extractBackendMessage(error);

    if (statusCode == 404) {
      return PortfolioItemNotFoundFailure(backendMessage);
    }
    if (statusCode == 400) {
      return PortfolioValidationFailure(backendMessage);
    }
    return const PortfolioServiceUnavailableFailure();
  }

  /// El envelope de error del backend es `{success:false, error:{code,message,...}}` —
  /// `EnvelopeInterceptor` solo desenvuelve respuestas exitosas, así que esto llega crudo.
  String? _extractBackendMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['message'] as String?;
    }
    return null;
  }
}
