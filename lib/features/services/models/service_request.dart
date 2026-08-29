import 'request_status.dart';

/// `ServiceRequests` — desde 0008-id-referenceid-standardization el backend expone `id` (Int
/// interno, secuencial) y `referenceId` (UUID) por separado (ver `openspec/decisions.md`). `id`
/// sirve SOLO para ordenamiento, nunca para navegar/consultar/rutear — usar siempre `referenceId`
/// para eso. `serviceId` sigue siendo el UUID del `Service` padre (el backend lo mapea explícito
/// desde el `referenceId` de la relación, no es el Int interno — no cambió). `professionalId`
/// sigue siendo el Int crudo de `Professionals`.
class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.referenceId,
    required this.serviceId,
    required this.professionalId,
    required this.status,
    required this.createdAt,
    this.proposedPrice,
    this.proposedHours,
    this.message,
  });

  /// Int interno secuencial — solo para ordenamiento, nunca para navegar/consultar/rutear.
  final int id;

  /// UUID público — la clave real para navegación/deep-linking y lookups por API.
  final String referenceId;
  final String serviceId;
  final int professionalId;
  final RequestStatus status;
  final double? proposedPrice;
  final double? proposedHours;
  final String? message;
  final DateTime createdAt;

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
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
