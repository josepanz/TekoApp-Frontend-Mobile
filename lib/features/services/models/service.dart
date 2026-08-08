import 'service_status.dart';

/// Categoría resumida tal cual la anida `ServiceDetailResponseDTO.category` — no es el mismo
/// modelo que `features/categories/models/category.dart` (ese trae `referenceId`/
/// `parentCategoryId`, este es solo lo que el backend anida dentro de un `Service`).
class ServiceCategorySummary {
  const ServiceCategorySummary({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
  });

  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;

  factory ServiceCategorySummary.fromJson(Map<String, dynamic> json) {
    return ServiceCategorySummary(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }
}

/// Cliente dueño del servicio — el backend lo expone bajo la clave JSON `users` (así, en plural,
/// pese a ser un solo objeto: `ServiceDetailResponseDTO.users`). Necesario para que el
/// profesional pueda calificar al cliente (`referenceId` es lo que pide
/// `CreateProfessionalToClientRatingRequestDTO.clientId`).
class ServiceClientSummary {
  const ServiceClientSummary({
    required this.referenceId,
    required this.firstName,
    required this.lastName,
  });

  final String referenceId;
  final String firstName;
  final String lastName;

  factory ServiceClientSummary.fromJson(Map<String, dynamic> json) {
    return ServiceClientSummary(
      referenceId: json['referenceId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
    );
  }
}

/// Profesional asignado, con el nombre ya aplanado desde `professional.user` — la UI de esta fase
/// solo necesita mostrar un nombre, no el resto del perfil del usuario.
class ServiceProfessionalSummary {
  const ServiceProfessionalSummary({
    required this.id,
    required this.referenceId,
    required this.firstName,
    required this.lastName,
  });

  final int id;
  final String referenceId;
  final String firstName;
  final String lastName;

  factory ServiceProfessionalSummary.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return ServiceProfessionalSummary(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      firstName: user['firstName'] as String,
      lastName: user['lastName'] as String,
    );
  }
}

/// `Services` — el `id` YA ES el `referenceId` (UUID): el backend usa UUID como PK primaria para
/// esta tabla y `exposeReferenceAsId()` borra el Int interno de la respuesta (ver
/// `openspec/decisions.md`, no aplica el patrón `id` Int + `referenceId` separado que sí usan
/// `Category`/`Professionals`).
///
/// `userId`/`professionalId` SÍ son el Int interno crudo de `Users`/`Professionals` — el backend
/// no los limpia en este endpoint. No usarlos para navegación/rutas; solo sirven para comparar
/// "¿es mi servicio?"/"¿soy el profesional asignado?" contra el `id` numérico del usuario logueado
/// (`GET /auth/scope`, que sí expone ese mismo Int).
class Service {
  const Service({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.serviceTypeId,
    required this.title,
    required this.description,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.isUrgent,
    required this.createdAt,
    this.professionalId,
    this.hourlyRate,
    this.fixedPrice,
    this.totalAmount,
    this.finalAmount,
    this.estimatedHours,
    this.additionalNotes,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.category,
    this.professional,
    this.client,
  });

  final String id;
  final int userId;
  final int? professionalId;
  final int categoryId;
  final int serviceTypeId;
  final String title;
  final String description;
  final ServiceStatus status;
  final double? estimatedHours;
  final double? hourlyRate;
  final double? fixedPrice;
  final double? totalAmount;
  final double? finalAmount;
  final double latitude;
  final double longitude;
  final String address;
  final String? additionalNotes;
  final bool isUrgent;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final ServiceCategorySummary? category;
  final ServiceProfessionalSummary? professional;
  final ServiceClientSummary? client;

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      userId: json['userId'] as int,
      professionalId: json['professionalId'] as int?,
      categoryId: json['categoryId'] as int,
      serviceTypeId: json['serviceTypeId'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      status: ServiceStatus.fromJson(json['status'] as String),
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      fixedPrice: (json['fixedPrice'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      finalAmount: (json['finalAmount'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String,
      additionalNotes: json['additionalNotes'] as String?,
      isUrgent: json['isUrgent'] as bool,
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      cancelledAt: _parseDate(json['cancelledAt']),
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] != null
          ? ServiceCategorySummary.fromJson(
              json['category'] as Map<String, dynamic>,
            )
          : null,
      professional: json['professional'] != null
          ? ServiceProfessionalSummary.fromJson(
              json['professional'] as Map<String, dynamic>,
            )
          : null,
      client: json['users'] != null
          ? ServiceClientSummary.fromJson(json['users'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}
