// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "ServiceDetailResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'service.dart';

Service _$ServiceFromJson(Map<String, dynamic> json) => Service(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      userId: json['userId'] as int,
      professionalId: json['professionalId'] as int?,
      categoryId: json['categoryId'] as int,
      serviceTypeId: json['serviceTypeId'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      status: ServiceStatus.fromJson(json['status'] as String),
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      actualHours: (json['actualHours'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      fixedPrice: (json['fixedPrice'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      finalAmount: (json['finalAmount'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      additionalNotes: json['additionalNotes'] as String?,
      images: (json['images'] as List<dynamic>).cast<String>(),
      isUrgent: json['isUrgent'] as bool,
      scheduledAt: json['scheduledAt'] == null
          ? null
          : DateTime.parse(json['scheduledAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      client:
          ServiceClientSummary.fromJson(json['users'] as Map<String, dynamic>),
      professional: json['professional'] == null
          ? null
          : ServiceProfessionalSummary.fromJson(
              json['professional'] as Map<String, dynamic>),
      category: json['category'] == null
          ? null
          : ServiceCategorySummary.fromJson(
              json['category'] as Map<String, dynamic>),
    );
