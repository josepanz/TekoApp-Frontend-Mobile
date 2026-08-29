import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/payment.dart';
import '../models/payment_failure.dart';
import '../models/payment_method.dart';
import '../models/tip.dart';
import '../models/tip_mode.dart';

/// `/payments`/`/payments/methods` — todo el árbol exige JWT (ya cubierto por
/// `BearerAuthInterceptor`). Sin tokenización real de proveedor en esta fase (ver
/// `openspec/decisions.md`): los métodos de pago se cargan con lo que el usuario ingresa a mano.
class PaymentsRepository {
  PaymentsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      final response = await _apiClient.raw.get<List<dynamic>>(
        '/payments/methods',
      );
      return (response.data ?? [])
          .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<PaymentMethod> createPaymentMethod({
    required String name,
    required PaymentMethodType type,
    required PaymentProviderType provider,
    bool? isDefault,
    Map<String, dynamic>? details,
    String? externalId,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/payments/methods',
        data: {
          'name': name,
          'type': type.toJson(),
          'provider': provider.toJson(),
          if (isDefault != null) 'isDefault': isDefault,
          if (details != null) 'details': details,
          if (externalId != null) 'externalId': externalId,
        },
      );
      return PaymentMethod.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<PaymentMethod> setPaymentMethodAsDefault(String id) async {
    try {
      final response = await _apiClient.raw.put<Map<String, dynamic>>(
        '/payments/methods/$id',
        data: {'isDefault': true},
      );
      return PaymentMethod.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// El backend rechaza esto con un mensaje textual propio
  /// (`payments.CANNOT_DELETE_ONLY_METHOD`) si es el único método activo — se propaga tal cual en
  /// [PaymentConflictFailure.backendMessage], no se muestra un mensaje genérico.
  Future<void> deletePaymentMethod(String id) async {
    try {
      await _apiClient.raw.delete<void>('/payments/methods/$id');
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<Payment> createPayment({
    required String professionalReferenceId,
    required String serviceId,
    required double amount,
    required String currencyCode,
    required PaymentMethodType paymentMethod,
    required PaymentProviderType paymentProvider,
    String? paymentMethodId,
    String? description,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/payments',
        data: {
          'professionalId': professionalReferenceId,
          'serviceId': serviceId,
          'amount': amount,
          'currencyCode': currencyCode,
          'paymentMethod': paymentMethod.toJson(),
          'paymentProvider': paymentProvider.toJson(),
          if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
          if (description != null) 'description': description,
        },
      );
      return Payment.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// `userId`/`professionalId`: el Int interno, no el UUID — ver `openspec/decisions.md` para
  /// cómo se resuelve el propio en cada modo (cliente/profesional).
  Future<List<Payment>> fetchPayments({
    int? userId,
    int? professionalId,
  }) async {
    try {
      final response = await _apiClient.raw.get<List<dynamic>>(
        '/payments',
        queryParameters: {
          if (userId != null) 'userId': userId,
          if (professionalId != null) 'professionalId': professionalId,
        },
      );
      return (response.data ?? [])
          .map((json) => Payment.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<Payment> fetchPaymentById(String id) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/payments/$id',
      );
      return Payment.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// El backend rechaza esto con mensajes textuales propios
  /// (`payments.ONLY_COMPLETED_CAN_BE_REFUNDED`/`payments.REFUND_EXCEEDS_AVAILABLE`) — mismo
  /// criterio que `deletePaymentMethod`.
  Future<Payment> refundPayment(
    String id, {
    required double amount,
    required String reason,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/payments/$id/refund',
        data: {'amount': amount, 'reason': reason},
      );
      return Payment.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<TipConfig> fetchTipConfig() async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/tips/config',
      );
      return TipConfig.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// El backend rechaza esto con mensajes textuales propios
  /// (`tips.PAYMENT_NOT_ELIGIBLE`/`tips.ALREADY_TIPPED`/`tips.TIPS_DISABLED`) — mismo criterio
  /// que `deletePaymentMethod`/`refundPayment`.
  Future<Tip> createTip(
    String paymentReferenceId, {
    required TipMode mode,
    double? percentage,
    double? amount,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/payments/$paymentReferenceId/tip',
        data: {
          'mode': mode.toJson(),
          if (percentage != null) 'percentage': percentage,
          if (amount != null) 'amount': amount,
        },
      );
      return Tip.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  PaymentFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    final backendMessage = _extractBackendMessage(error);
    if (statusCode == 409) {
      return PaymentConflictFailure(backendMessage);
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return PaymentValidationFailure(backendMessage);
    }
    return const PaymentServiceUnavailableFailure();
  }

  /// El envelope de error del backend es `{success:false, error:{code,message,...}}` —
  /// `EnvelopeInterceptor` solo desenvuelve respuestas exitosas, así que esto llega crudo (ver
  /// `openspec/decisions.md`).
  String? _extractBackendMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorField = data['error'];
      if (errorField is Map<String, dynamic>) {
        return errorField['message'] as String?;
      }
    }
    return null;
  }
}
