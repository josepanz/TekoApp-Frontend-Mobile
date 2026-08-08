import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/promotion_apply_result.dart';
import '../models/promotion_failure.dart';
import '../models/promotion_validation.dart';

/// `/promotions/validate` (preview) y `/promotions/apply` (efecto real) — todo el árbol exige JWT
/// (ya cubierto por `BearerAuthInterceptor`). Ver `openspec/decisions.md` para por qué nunca se
/// llama `apply` como preview.
class PromotionsRepository {
  PromotionsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PromotionValidation> validate({
    required String code,
    required double serviceAmount,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/promotions/validate',
        data: {'code': code, 'serviceAmount': serviceAmount},
      );
      return PromotionValidation.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<PromotionApplyResult> apply({
    required String code,
    required double serviceAmount,
    String? serviceId,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/promotions/apply',
        data: {
          'promotionCode': code,
          'serviceAmount': serviceAmount,
          if (serviceId != null) 'serviceId': serviceId,
        },
      );
      return PromotionApplyResult.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  PromotionFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return const PromotionValidationFailure();
    }
    return const PromotionServiceUnavailableFailure();
  }
}
