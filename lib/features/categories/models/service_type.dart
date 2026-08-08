/// Tipo de servicio (`GET /service-types`) — catálogo plano, sin relación a `Category` en el
/// backend (confirmado en `prisma/schema.prisma`: `ServiceType` no tiene `categoryId`). No filtra
/// por categoría, es el mismo combo global para cualquier categoría elegida.
class ServiceType {
  const ServiceType({required this.id, required this.name});

  final int id;
  final String name;

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    return ServiceType(id: json['id'] as int, name: json['name'] as String);
  }
}
