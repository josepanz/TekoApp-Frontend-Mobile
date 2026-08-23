/// Espeja el enum `DeviceType` de `schema.prisma` en el backend (`WEB`/`ANDROID`/`IOS`).
enum DeviceType {
  android,
  ios;

  String toJson() => switch (this) {
        DeviceType.android => 'ANDROID',
        DeviceType.ios => 'IOS',
      };
}
