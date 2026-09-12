/// Categoría de bloqueante que impide iniciar el borrado de cuenta — ver
/// `TekoApp-Backend/openspec/changes/platform-hardening-2026-09/I-01-account-deletion.md`,
/// `DeletionBlockerType`. Ninguno se resuelve automáticamente: cada uno navega al flujo normal de
/// esa feature (cancelar el servicio, esperar el pago, firmar/cancelar el contrato).
enum DeletionBlockerType {
  activeService,
  pendingPayment,
  unsignedContract,
  unknown;

  /// El backend puede agregar un tipo nuevo (ej. disputa abierta, I-03, todavía no implementado
  /// del lado backend) — `unknown` evita que un valor no reconocido tumbe el parseo entero de la
  /// lista de bloqueantes.
  factory DeletionBlockerType.fromJson(String value) {
    return switch (value) {
      'ACTIVE_SERVICE' => DeletionBlockerType.activeService,
      'PENDING_PAYMENT' => DeletionBlockerType.pendingPayment,
      'UNSIGNED_CONTRACT' => DeletionBlockerType.unsignedContract,
      _ => DeletionBlockerType.unknown,
    };
  }
}

/// Un elemento de `details.blockers` del `409 DELETION_BLOCKED` (ver `AccountDeletionService.
/// findBlockers` del backend) — tipo + cuántos casos de ese tipo aplican.
class DeletionBlocker {
  const DeletionBlocker({required this.type, required this.count});

  final DeletionBlockerType type;
  final int count;

  factory DeletionBlocker.fromJson(Map<String, dynamic> json) {
    return DeletionBlocker(
      type: DeletionBlockerType.fromJson(json['type'] as String),
      count: json['count'] as int,
    );
  }
}
