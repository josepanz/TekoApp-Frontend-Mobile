/// Estados de `Services` (`prisma/schema.prisma`, enum `ServiceStatus`) — transición lineal
/// PENDING → ACCEPTED → IN_PROGRESS → COMPLETED, con CANCELLED alcanzable desde PENDING/ACCEPTED
/// (ver `openspec/specs/services-marketplace.md`). La UI nunca ofrece una transición fuera de este
/// orden — el backend la rechazaría con 409/400 igual.
enum ServiceStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled;

  static ServiceStatus fromJson(String value) {
    switch (value) {
      case 'PENDING':
        return ServiceStatus.pending;
      case 'ACCEPTED':
        return ServiceStatus.accepted;
      case 'IN_PROGRESS':
        return ServiceStatus.inProgress;
      case 'COMPLETED':
        return ServiceStatus.completed;
      case 'CANCELLED':
        return ServiceStatus.cancelled;
      default:
        throw ArgumentError('ServiceStatus desconocido: $value');
    }
  }
}
