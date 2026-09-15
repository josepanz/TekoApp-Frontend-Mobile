/// Espeja `AiDisclosureEntityType` de Prisma — introducido junto con `0006`/`0012` (consentimiento)
/// porque `ContentConsentGrants` ya lo usa como tipo de contenido; la Fase `0011`
/// (ai-content-disclosure) reusa este mismo tipo cuando se implemente, ver
/// `TekoApp-Backend/openspec/decisions.md`.
enum AiDisclosureEntityType {
  serviceDescription,
  budgetOption,
  progressNote,
  professionalDescription,
  image,
  other;

  static AiDisclosureEntityType fromJson(String value) {
    switch (value) {
      case 'SERVICE_DESCRIPTION':
        return AiDisclosureEntityType.serviceDescription;
      case 'BUDGET_OPTION':
        return AiDisclosureEntityType.budgetOption;
      case 'PROGRESS_NOTE':
        return AiDisclosureEntityType.progressNote;
      case 'PROFESSIONAL_DESCRIPTION':
        return AiDisclosureEntityType.professionalDescription;
      case 'IMAGE':
        return AiDisclosureEntityType.image;
      case 'OTHER':
        return AiDisclosureEntityType.other;
      default:
        // M-04 §11.1: catch-all defensivo que absorbe en silencio (no relanza) un valor futuro
        // que el schema agregue y este enum todavía no cubra explícitamente — mismo criterio ya
        // documentado en `AiDisclosureSource`. Con `OTHER` ahora como case explícito (arriba), el
        // verificador de drift solo reporta ADVERTENCIA (no crítico) si el schema agrega otro
        // valor más — nunca CRASHEA, a diferencia de `LegalDocumentType`, que si relanza.
        return AiDisclosureEntityType.other;
    }
  }

  String toJson() {
    switch (this) {
      case AiDisclosureEntityType.serviceDescription:
        return 'SERVICE_DESCRIPTION';
      case AiDisclosureEntityType.budgetOption:
        return 'BUDGET_OPTION';
      case AiDisclosureEntityType.progressNote:
        return 'PROGRESS_NOTE';
      case AiDisclosureEntityType.professionalDescription:
        return 'PROFESSIONAL_DESCRIPTION';
      case AiDisclosureEntityType.image:
        return 'IMAGE';
      case AiDisclosureEntityType.other:
        return 'OTHER';
    }
  }
}
