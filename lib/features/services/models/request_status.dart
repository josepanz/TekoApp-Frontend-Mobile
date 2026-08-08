/// Estados de `ServiceRequests` (`prisma/schema.prisma`, enum `RequestStatus`). `expired` existe
/// en el schema pero ningún código del backend lo produce hoy (ver `openspec/decisions.md`) — no
/// diseñar UI que dependa de que una propuesta expire sola.
enum RequestStatus {
  pending,
  accepted,
  rejected,
  expired;

  static RequestStatus fromJson(String value) {
    switch (value) {
      case 'PENDING':
        return RequestStatus.pending;
      case 'ACCEPTED':
        return RequestStatus.accepted;
      case 'REJECTED':
        return RequestStatus.rejected;
      case 'EXPIRED':
        return RequestStatus.expired;
      default:
        throw ArgumentError('RequestStatus desconocido: $value');
    }
  }

  String toJson() {
    switch (this) {
      case RequestStatus.pending:
        return 'PENDING';
      case RequestStatus.accepted:
        return 'ACCEPTED';
      case RequestStatus.rejected:
        return 'REJECTED';
      case RequestStatus.expired:
        return 'EXPIRED';
    }
  }
}
