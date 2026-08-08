import 'rating_type.dart';

/// `Rating` — el `id` ya es el `referenceId` (UUID). `userId`/`professionalId` son el Int interno
/// crudo (mismo patrón que `Service`, ver `openspec/decisions.md`).
class Rating {
  const Rating({
    required this.id,
    required this.userId,
    required this.professionalId,
    required this.type,
    required this.rating,
    required this.isAnonymous,
    required this.isActive,
    required this.createdAt,
    this.review,
  });

  final String id;
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
      id: json['id'] as String,
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
