import 'package:dio/dio.dart';

import '../../../core/api_client/api_client.dart';
import '../models/request_status.dart';
import '../models/service.dart';
import '../models/service_failure.dart';
import '../models/service_request.dart';
import '../models/service_status.dart';

/// `Services`/`ServiceRequests` — todo el árbol de `/services` exige JWT (ya cubierto por
/// `BearerAuthInterceptor`, ver `openspec/decisions.md`). Online-only: sin caché entre sesiones,
/// cada pantalla decide cuándo refetchear. Paginación: solo primera página por ahora (ver
/// `openspec/decisions.md`).
class ServicesRepository {
  ServicesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Service> createService({
    required String title,
    required String description,
    required int categoryId,
    required int serviceTypeId,
    required double latitude,
    required double longitude,
    required String address,
    double? estimatedHours,
    double? hourlyRate,
    double? fixedPrice,
    String? additionalNotes,
    bool? isUrgent,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/services',
        data: {
          'title': title,
          'description': description,
          'categoryId': categoryId,
          'serviceTypeId': serviceTypeId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          if (estimatedHours != null) 'estimatedHours': estimatedHours,
          if (hourlyRate != null) 'hourlyRate': hourlyRate,
          if (fixedPrice != null) 'fixedPrice': fixedPrice,
          if (additionalNotes != null) 'additionalNotes': additionalNotes,
          if (isUrgent != null) 'isUrgent': isUrgent,
        },
      );
      return Service.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// `role`: `'client'` (servicios que pedí) o `'professional'` (servicios que tengo asignados).
  Future<List<Service>> fetchMyServices({
    required String role,
    ServiceStatus? status,
  }) async {
    try {
      final response = await _apiClient.raw.get<List<dynamic>>(
        '/services/my-services',
        queryParameters: {
          'role': role,
          if (status != null) 'status': _statusToJson(status),
        },
      );
      return (response.data ?? [])
          .map((json) => Service.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<Service> fetchServiceDetail(String id) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/services/$id',
      );
      return Service.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// Servicios PENDING sin profesional asignado en la categoría del profesional autenticado — no
  /// existe un endpoint dedicado en el backend, se arma con el filtro general (ver
  /// `openspec/decisions.md`). Solo primera página.
  Future<List<Service>> fetchAvailableServices({
    required int categoryId,
  }) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/services',
        queryParameters: {
          'status': 'PENDING',
          'categoryId': categoryId,
          'page': 1,
        },
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => Service.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<List<ServiceRequest>> fetchServiceRequests(String serviceId) async {
    try {
      final response = await _apiClient.raw.get<Map<String, dynamic>>(
        '/services/$serviceId/requests',
      );
      final data = response.data?['data'] as List<dynamic>? ?? [];
      return data
          .map((json) => ServiceRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<ServiceRequest> proposeOnService(
    String serviceId, {
    double? proposedPrice,
    double? proposedHours,
    String? message,
  }) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/services/$serviceId/requests',
        data: {
          if (proposedPrice != null) 'proposedPrice': proposedPrice,
          if (proposedHours != null) 'proposedHours': proposedHours,
          if (message != null) 'message': message,
        },
      );
      return ServiceRequest.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  /// El cliente acepta o rechaza una propuesta puntual. Al aceptar, el backend rechaza las demás
  /// propuestas competidoras del mismo servicio en una transacción — no hace falta iterar
  /// rechazándolas desde acá (ver `openspec/decisions.md`).
  Future<ServiceRequest> respondToRequest(
    String serviceId,
    String requestId,
    RequestStatus status, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.raw.put<Map<String, dynamic>>(
        '/services/$serviceId/requests/$requestId',
        data: {'status': status.toJson(), if (reason != null) 'reason': reason},
      );
      return ServiceRequest.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<Service> startService(String id) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/services/$id/start',
      );
      return Service.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<Service> completeService(String id) async {
    try {
      final response = await _apiClient.raw.post<Map<String, dynamic>>(
        '/services/$id/complete',
      );
      return Service.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  Future<Service> cancelService(String id, String reason) async {
    try {
      final response = await _apiClient.raw.delete<Map<String, dynamic>>(
        '/services/$id',
        data: {'reason': reason},
      );
      return Service.fromJson(response.data!);
    } on DioException catch (error) {
      throw _classify(error);
    }
  }

  String _statusToJson(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return 'PENDING';
      case ServiceStatus.accepted:
        return 'ACCEPTED';
      case ServiceStatus.inProgress:
        return 'IN_PROGRESS';
      case ServiceStatus.completed:
        return 'COMPLETED';
      case ServiceStatus.cancelled:
        return 'CANCELLED';
    }
  }

  ServiceFailure _classify(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 409) {
      return const ServiceConflictFailure();
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return const ServiceValidationFailure();
    }
    return const ServiceServiceUnavailableFailure();
  }
}
