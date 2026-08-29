import 'rating_type.dart';

/// `Rating` — desde 0008-id-referenceid-standardization el backend expone `id` (Int interno,
/// secuencial) y `referenceId` (UUID) por separado (ver `openspec/decisions.md`). `id` sirve SOLO
/// para ordenamiento, nunca para navegar/consultar/rutear — usar siempre `referenceId` para eso.
/// `userId`/`professionalId` son el Int interno crudo (mismo patrón que `Service`).
class Rating {
  const Rating({
    required this.id,
    required this.referenceId,
    required this.userId,
    required this.professionalId,
    required this.type,
    required this.rating,
    required this.isAnonymous,
    required this.isActive,
    required this.createdAt,
    this.review,
  });

  /// Int interno secuencial — solo para ordenamiento, nunca para navegar/consultar/rutear.
  final int id;

  /// UUID público — la clave real para navegación/deep-linking y lookups por API.
  final String referenceId;
  final int userId;
  final int professionalId;
  final RatingType type;
  final double rating;
  final String? review;
  final bool isAnonymous;
  final bool isActive;
  final DateTime createdAt;

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      userId: json['userId'] as int,
      professionalId: json['professionalId'] as int,
      type: RatingType.fromJson(json['type'] as String),
      rating: (json['rating'] as num).toDouble(),
      review: json['review'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
