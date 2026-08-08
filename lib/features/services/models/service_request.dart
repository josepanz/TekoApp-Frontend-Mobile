import 'request_status.dart';

/// `ServiceRequests` — igual que `Service`, el `id` YA ES el UUID (PK primaria de la tabla, ver
/// `openspec/decisions.md`). `serviceId` es el UUID del `Service` padre (el backend lo mapea
/// explícito desde el `referenceId` de la relación, no es el Int interno). `professionalId` sigue
/// siendo el Int crudo de `Professionals`.
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.serviceId,
    required this.professionalId,
    required this.status,
    required this.createdAt,
    this.proposedPrice,
    this.proposedHours,
    this.message,
  });

  final String id;
  final String serviceId;
  final int professionalId;
  final RequestStatus status;
  final double? proposedPrice;
  final double? proposedHours;
  final String? message;
  final DateTime createdAt;

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      professionalId: json['professionalId'] as int,
      status: RequestStatus.fromJson(json['status'] as String),
      proposedPrice: (json['proposedPrice'] as num?)?.toDouble(),
      proposedHours: (json['proposedHours'] as num?)?.toDouble(),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
