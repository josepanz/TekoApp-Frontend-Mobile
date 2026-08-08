/// Estado del pago — mismo enum `PaymentStatus` de `TekoApp-Backend`.
enum PaymentStatus {
  pending,
  processing,
  completed,
  paid,
  failed,
  refunded,
  partialRefunded,
  cancelled;

  factory PaymentStatus.fromJson(String value) {
    return switch (value) {
      'PENDING' => PaymentStatus.pending,
      'PROCESSING' => PaymentStatus.processing,
      'COMPLETED' => PaymentStatus.completed,
      'PAID' => PaymentStatus.paid,
      'FAILED' => PaymentStatus.failed,
      'REFUNDED' => PaymentStatus.refunded,
      'PARTIAL_REFUNDED' => PaymentStatus.partialRefunded,
      'CANCELLED' => PaymentStatus.cancelled,
      _ => throw ArgumentError('PaymentStatus desconocido: $value'),
    };
  }
}
