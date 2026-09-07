import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../core/api_client/api_client.dart';
import '../models/my_document_status.dart';
import '../models/professional_document.dart';
import '../models/professional_document_failure.dart';

/// `/professionals/me/documents`, `/professionals/:referenceId/documents/public` — todo el árbol
/// exige JWT (ya cubierto por `BearerAuthInterceptor`). Ver
/// `TekoApp-Backend/openspec/specs/professional-documents.md`.
///
/// A diferencia de `service_progress`, acá el archivo SÍ viaja en el mismo POST que crea el
/// documento (multipart directo) — el backend reusa `modules/storage` internamente, no el
/// endpoint genérico `/uploads/*` (ver decisión en `openspec/specs/professional-documents.md`).
class ProfessionalDocumentsRepository {
  ProfessionalDocumentsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MyDocumentStatus>> myDocuments() async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/professionals/me/documents',
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((e) => MyDocumentStatus.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// `Professionals.requiredDocumentsVerified` (booleano) — el derivado que se muestra al cliente
  /// como badge de "antecedentes verificados", NUNCA el documento de antecedentes en sí (ese ni
  /// siquiera llega acá: `isVisibleToClient=false` por convención de catálogo para
  /// `BACKGROUND_CHECK`, filtrado server-side). Distinto de `verificationStatus` (aprobación
  /// manual de staff sobre la cuenta, sin relación con documentos — colisión real encontrada en
  /// backend, ver `openspec/decisions.md`; NUNCA leer `verificationStatus` para este badge).
  /// No existe todavía una feature `professionals` completa en mobile — se resuelve este único
  /// campo acá, scoped a esta feature, en vez de armar un modelo/repositorio de perfil profesional
  /// completo sin que se haya pedido.
  Future<bool> isVerified(String professionalReferenceId) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/professionals/$professionalReferenceId',
      );
      return response.data!['requiredDocumentsVerified'] as bool;
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<List<ProfessionalDocument>> publicDocuments(
    String professionalReferenceId,
  ) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/professionals/$professionalReferenceId/documents/public',
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map(
            (e) => ProfessionalDocument.fromJson(e as Map<String, dynamic>),
          )
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
      throw const ProfessionalDocumentServiceUnavailableFailure();
    }
  }

  Future<ProfessionalDocument> upload({
    required String professionalDocumentTypeReferenceId,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    DateTime? issuedAt,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/professionals/me/documents',
        data: FormData.fromMap({
          'professionalDocumentTypeReferenceId':
              professionalDocumentTypeReferenceId,
          if (issuedAt != null) 'issuedAt': issuedAt.toUtc().toIso8601String(),
          'file': MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        }),
      );
      return ProfessionalDocument.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  ProfessionalDocumentFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final backendMessage = _extractBackendMessage(error);

    if (statusCode == 404) {
      return ProfessionalDocumentTypeNotApplicableFailure(backendMessage);
    }
    if (statusCode == 400) {
      return ProfessionalDocumentValidationFailure(backendMessage);
    }
    return const ProfessionalDocumentServiceUnavailableFailure();
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
