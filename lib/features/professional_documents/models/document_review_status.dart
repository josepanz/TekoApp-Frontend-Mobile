/// `ProfessionalDocuments.status` (enum `DocumentReviewStatus` del backend).
enum DocumentReviewStatus {
  pending,
  approved,
  rejected,
  expired;

  static DocumentReviewStatus fromJson(String value) {
    switch (value) {
      case 'PENDING':
        return DocumentReviewStatus.pending;
      case 'APPROVED':
        return DocumentReviewStatus.approved;
      case 'REJECTED':
        return DocumentReviewStatus.rejected;
      case 'EXPIRED':
        return DocumentReviewStatus.expired;
      default:
        throw ArgumentError('DocumentReviewStatus desconocido: $value');
    }
  }
}
