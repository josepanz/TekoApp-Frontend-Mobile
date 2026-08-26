/// Espeja `ContentUsageScope` de Prisma — alcance de uso elegido por el uploader para un
/// contenido puntual (ver `openspec/specs/data-and-media-consent.md`).
enum ContentUsageScope {
  appInternalOnly,
  publicProfileDisplay,
  marketing;

  static ContentUsageScope fromJson(String value) {
    switch (value) {
      case 'APP_INTERNAL_ONLY':
        return ContentUsageScope.appInternalOnly;
      case 'PUBLIC_PROFILE_DISPLAY':
        return ContentUsageScope.publicProfileDisplay;
      case 'MARKETING':
        return ContentUsageScope.marketing;
      default:
        throw ArgumentError('ContentUsageScope desconocido: $value');
    }
  }

  String toJson() {
    switch (this) {
      case ContentUsageScope.appInternalOnly:
        return 'APP_INTERNAL_ONLY';
      case ContentUsageScope.publicProfileDisplay:
        return 'PUBLIC_PROFILE_DISPLAY';
      case ContentUsageScope.marketing:
        return 'MARKETING';
    }
  }
}
