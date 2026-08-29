/// Espeja `AiDisclosureSource` de Prisma (`TekoApp-Backend/prisma/schema.prisma`).
enum AiDisclosureSource {
  platformAi,
  userDeclaredAi;

  static AiDisclosureSource fromJson(String value) {
    switch (value) {
      case 'PLATFORM_AI':
        return AiDisclosureSource.platformAi;
      case 'USER_DECLARED_AI':
        return AiDisclosureSource.userDeclaredAi;
      default:
        return AiDisclosureSource.userDeclaredAi;
    }
  }

  String toJson() {
    switch (this) {
      case AiDisclosureSource.platformAi:
        return 'PLATFORM_AI';
      case AiDisclosureSource.userDeclaredAi:
        return 'USER_DECLARED_AI';
    }
  }
}
