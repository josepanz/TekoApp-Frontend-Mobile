/// `ProfessionalPortfolioItems.status` (enum `PortfolioReviewStatus` del backend).
enum PortfolioReviewStatus {
  pending,
  approved,
  rejected;

  static PortfolioReviewStatus fromJson(String value) {
    switch (value) {
      case 'PENDING':
        return PortfolioReviewStatus.pending;
      case 'APPROVED':
        return PortfolioReviewStatus.approved;
      case 'REJECTED':
        return PortfolioReviewStatus.rejected;
      default:
        throw ArgumentError('PortfolioReviewStatus desconocido: $value');
    }
  }
}
