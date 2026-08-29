/// Una entrada de la bitácora de avance de un `Service` (`ServiceProgressEntryResponseDTO`) — ver
/// `openspec/specs/work-progress-log.md`. `referenceId` es el único identificador expuesto (no hay
/// `id` numérico separado en este dominio, mismo patrón que `ai_disclosures`/`legal_consents`).
class ServiceProgressEntry {
  const ServiceProgressEntry({
    required this.referenceId,
    required this.images,
    required this.entryOrder,
    required this.createdAt,
    required this.editWindowExpired,
    this.note,
  });

  final String referenceId;
  final String? note;
  final List<String> images;
  final int entryOrder;
  final DateTime createdAt;

  /// Calculado por el backend contra su propia hora de servidor — usar esto para decidir si
  /// mostrar el botón de eliminar, no reimplementar el cálculo de ventana en el cliente (evita
  /// desfasajes de reloj del dispositivo, ver `openspec/changes/0008-work-progress-log.md`).
  final bool editWindowExpired;

  factory ServiceProgressEntry.fromJson(Map<String, dynamic> json) {
    return ServiceProgressEntry(
      referenceId: json['referenceId'] as String,
      note: json['note'] as String?,
      images: (json['images'] as List<dynamic>).cast<String>(),
      entryOrder: json['entryOrder'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      editWindowExpired: json['editWindowExpired'] as bool,
    );
  }
}
