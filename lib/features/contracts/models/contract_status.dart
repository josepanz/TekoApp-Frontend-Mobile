/// Espejo de `ContractStatus` del backend.
enum ContractStatus {
  draft,
  pendingClientSignature,
  pendingProfessionalSignature,
  signed,
  cancelled;

  factory ContractStatus.fromJson(String value) {
    return switch (value) {
      'DRAFT' => ContractStatus.draft,
      'PENDING_CLIENT_SIGNATURE' => ContractStatus.pendingClientSignature,
      'PENDING_PROFESSIONAL_SIGNATURE' =>
        ContractStatus.pendingProfessionalSignature,
      'SIGNED' => ContractStatus.signed,
      'CANCELLED' => ContractStatus.cancelled,
      _ => throw ArgumentError('ContractStatus desconocido: $value'),
    };
  }
}
