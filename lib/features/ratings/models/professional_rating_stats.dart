/// `ProfessionalRatingStatsResponseDTO` — promedio/distribución de las calificaciones que el
/// profesional recibió como profesional (`CLIENT_TO_PROFESSIONAL`), sin identidad de quién/cuándo
/// — ver `openspec/decisions.md`, backlog "ratings anónimo + KPIs".
class ProfessionalRatingStats {
  const ProfessionalRatingStats({
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
    required this.averageCriteria,
  });

  final double averageRating;
  final int totalRatings;

  /// Claves `'1'`..`'5'` → cantidad de calificaciones con esa cantidad de estrellas.
  final Map<String, int> ratingDistribution;

  /// Nombre del criterio (ej. `puntualidad`) → promedio — vacío si nadie calificó por criterio.
  final Map<String, double> averageCriteria;

  factory ProfessionalRatingStats.fromJson(Map<String, dynamic> json) {
    final distribution = json['ratingDistribution'] as Map<String, dynamic>;
    final criteria = json['averageCriteria'] as Map<String, dynamic>;
    return ProfessionalRatingStats(
      averageRating: (json['averageRating'] as num).toDouble(),
      totalRatings: json['totalRatings'] as int,
      ratingDistribution: distribution.map(
        (key, value) => MapEntry(key, value as int),
      ),
      averageCriteria: criteria.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }
}
