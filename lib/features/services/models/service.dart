import 'service_status.dart';

part 'service.g.dart';

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
///
/// `id`/`email`/`phoneNumber` se muestran en la pantalla del servicio del profesional cuando el
/// cliente comparte sus datos de contacto (`Users.shareContactInfo`) — el backend enmascara
/// `email`/`phoneNumber` a `null` cuando el cliente eligió no compartirlos, por eso ambos campos
/// son nullable acá (`email` pasó a ser nullable con ese cambio, ver CODEGEN.md §13.2).
class ServiceClientSummary {
  const ServiceClientSummary({
    required this.id,
    required this.referenceId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phoneNumber,
  });

  final int id;
  final String referenceId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;

  factory ServiceClientSummary.fromJson(Map<String, dynamic> json) {
    return ServiceClientSummary(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
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

/// `Services` — desde 0008-id-referenceid-standardization el backend expone `id` (Int interno,
/// secuencial) y `referenceId` (UUID) por separado (ver `openspec/decisions.md`). `id` sirve
/// SOLO para ordenamiento, nunca para navegar/consultar/rutear — usar siempre `referenceId` para
/// eso.
///
/// `userId`/`professionalId` SÍ son el Int interno crudo de `Users`/`Professionals` — el backend
/// no los limpia en este endpoint. No usarlos para navegación/rutas; solo sirven para comparar
/// "¿es mi servicio?"/"¿soy el profesional asignado?" contra el `id` numérico del usuario logueado
/// (`GET /auth/scope`, que sí expone ese mismo Int).
///
/// `fromJson` está generado desde el schema real de `ServiceDetailResponseDTO` (ver M-04,
/// `tool/openapi_codegen/generate_model.dart` y `service.g.dart`) — validado contra `--openapi-url`
/// de un backend corriendo. Migrarlo expuso 2 cosas que el modelo a mano tenía mal:
/// `actualHours`/`images`/`scheduledAt` se descartaban en silencio (mismo patrón que B-01/M-05), y
/// `client` (la clave JSON es `users`, no `client`) se trataba como opcional cuando el backend lo
/// devuelve siempre — ver el docstring de [client].
class Service {
  const Service({
    required this.id,
    required this.referenceId,
    required this.userId,
    required this.categoryId,
    required this.serviceTypeId,
    required this.title,
    required this.description,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.images,
    required this.isUrgent,
    required this.createdAt,
    required this.client,
    this.professionalId,
    this.hourlyRate,
    this.fixedPrice,
    this.totalAmount,
    this.finalAmount,
    this.estimatedHours,
    this.actualHours,
    this.additionalNotes,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.category,
    this.professional,
  });

  /// Int interno secuencial — solo para ordenamiento, nunca para navegar/consultar/rutear.
  final int id;

  /// UUID público — la clave real para navegación/deep-linking y lookups por API.
  final String referenceId;
  final int userId;
  final int? professionalId;
  final int categoryId;
  final int serviceTypeId;
  final String title;
  final String description;
  final ServiceStatus status;
  final double? estimatedHours;

  /// Horas reales trabajadas — distinto de [estimatedHours]. Sin consumidor en la UI todavía.
  final double? actualHours;
  final double? hourlyRate;
  final double? fixedPrice;
  final double? totalAmount;
  final double? finalAmount;
  final double latitude;
  final double longitude;
  final String address;
  final String? additionalNotes;

  /// Fotos adjuntas al pedido — el backend siempre lo devuelve (puede ser `[]`). Sin consumidor
  /// en la UI todavía.
  final List<String> images;
  final bool isUrgent;

  /// Fecha/hora agendada para el servicio, si el cliente eligió una — distinto de [createdAt].
  /// Sin consumidor en la UI todavía.
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final ServiceCategorySummary? category;
  final ServiceProfessionalSummary? professional;

  /// Cliente dueño del servicio — el backend SIEMPRE lo devuelve (`ServiceDetailResponseDTO.users`
  /// es requerido, nunca `null`), a diferencia de lo que asumía este modelo antes de M-04.
  final ServiceClientSummary client;

  factory Service.fromJson(Map<String, dynamic> json) =>
      _$ServiceFromJson(json);
}
