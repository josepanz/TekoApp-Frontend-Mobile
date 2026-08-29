/// `UserRatingStatsResponseDTO` — estadísticas propias del cliente: cuántas calificaciones dio
/// (como cliente, a profesionales) y cuántas recibió (como cliente, de profesionales), sin
/// identidad de quién/cuándo — ver `openspec/decisions.md`, backlog "ratings anónimo + KPIs".
class UserRatingStats {
  const UserRatingStats({
    required this.givenRatings,
    required this.receivedRatings,
    required this.averageGivenRating,
    required this.averageReceivedRating,
  });

  final int givenRatings;
  final int receivedRatings;
  final double averageGivenRating;
  final double averageReceivedRating;

  factory UserRatingStats.fromJson(Map<String, dynamic> json) {
    return UserRatingStats(
      givenRatings: json['givenRatings'] as int,
      receivedRatings: json['receivedRatings'] as int,
      averageGivenRating: (json['averageGivenRating'] as num).toDouble(),
      averageReceivedRating: (json['averageReceivedRating'] as num)
          .toDouble(),
    );
  }
}
