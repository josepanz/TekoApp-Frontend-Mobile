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
      default:
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
