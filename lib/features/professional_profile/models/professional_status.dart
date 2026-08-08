/// Estados de `Professionals` (`prisma/schema.prisma`, enum `ProfessionalStatus`) — forzado a
/// `PENDING` por el backend al registrarse (`ProfessionalsDbService.create`), nunca elegible por
/// el cliente. Las transiciones a `APPROVED`/`REJECTED`/`SUSPENDED` son de uso admin, fuera de
/// alcance de esta app (ver `openspec/changes/0003-services-marketplace-core.md`).
enum ProfessionalStatus {
  pending,
  approved,
  rejected,
  suspended;

  static ProfessionalStatus fromJson(String value) {
    switch (value) {
      case 'PENDING':
        return ProfessionalStatus.pending;
      case 'APPROVED':
        return ProfessionalStatus.approved;
      case 'REJECTED':
        return ProfessionalStatus.rejected;
      case 'SUSPENDED':
        return ProfessionalStatus.suspended;
      default:
        throw ArgumentError('ProfessionalStatus desconocido: $value');
    }
  }
}
