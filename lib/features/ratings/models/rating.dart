import 'rating_type.dart';

part 'rating.g.dart';

/// `Rating` — desde 0008-id-referenceid-standardization el backend expone `id` (Int interno,
/// secuencial) y `referenceId` (UUID) por separado (ver `openspec/decisions.md`). `id` sirve SOLO
/// para ordenamiento, nunca para navegar/consultar/rutear — usar siempre `referenceId` para eso.
/// `userId`/`professionalId` son el Int interno crudo (mismo patrón que `Service`), pero pueden
/// llegar en `null`: el backend los devuelve así cuando `isAnonymous=true` y quien consulta no es
/// el autor de la calificación.
///
/// `fromJson` está generado desde el schema de `RatingDetailResponseDTO` (ver M-04,
/// `tool/openapi_codegen/generate_model.dart` y `rating.g.dart`) — si el backend agrega o
/// cambia un campo, regenerar `rating.g.dart` lo hace explícito en el diff en vez de descubrirse
/// en producción.
class Rating {
  const Rating({
    required this.id,
    required this.referenceId,
    required this.userId,
    required this.professionalId,
    required this.serviceId,
    required this.type,
    required this.rating,
    required this.review,
    required this.criteria,
    required this.isAnonymous,
    required this.isReported,
    required this.reportReason,
    required this.isActive,
    required this.createdAt,
    required this.createdBy,
  });

  /// Int interno secuencial — solo para ordenamiento, nunca para navegar/consultar/rutear.
  final int id;

  /// UUID público — la clave real para navegación/deep-linking y lookups por API.
  final String referenceId;

  /// `null` cuando `isAnonymous=true` y quien consulta no es el autor.
  final int? userId;

  /// `null` cuando `isAnonymous=true` y quien consulta no es el autor.
  final int? professionalId;

  /// UUID de la solicitud de servicio asociada.
  final String? serviceId;
  final RatingType type;
  final double rating;
  final String? review;

  /// Criterios puntuales de la calificación (p.ej. puntualidad, calidad) — sin consumidor en la
  /// UI todavía.
  final Map<String, dynamic>? criteria;
  final bool isAnonymous;
  final bool isReported;
  final String? reportReason;
  final bool isActive;
  final DateTime createdAt;

  /// `userId` de quien creó el registro (auditoría) — sin consumidor en la UI todavía.
  final String? createdBy;

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);
}
