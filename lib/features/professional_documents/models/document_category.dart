/// `ProfessionalDocumentTypes.category` (`prisma/schema.prisma`, enum `DocumentCategory` del
/// backend) — antecedentes policiales/judiciales, títulos/certificados, o portafolio de trabajos
/// previos. No confundir con `DocumentsType` (documento de identidad de la persona, sin
/// equivalente en mobile todavía).
enum DocumentCategory {
  backgroundCheck,
  qualification,
  portfolio;

  static DocumentCategory fromJson(String value) {
    switch (value) {
      case 'BACKGROUND_CHECK':
        return DocumentCategory.backgroundCheck;
      case 'QUALIFICATION':
        return DocumentCategory.qualification;
      case 'PORTFOLIO':
        return DocumentCategory.portfolio;
      default:
        throw ArgumentError('DocumentCategory desconocida: $value');
    }
  }
}
