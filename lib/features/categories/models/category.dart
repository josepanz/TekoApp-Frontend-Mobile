/// Categoría del catálogo de servicios (`GET /categories`, listado público filtrado
/// activo+visible — ver `openspec/specs/services-marketplace.md`).
///
/// A diferencia de `Services`/`ServiceRequests`, el backend expone acá AMBOS identificadores por
/// separado (`id` Int interno y `referenceId` UUID público) — ver `openspec/decisions.md`. Se
/// conserva `id` porque `POST /services` pide `categoryId` como Int, no como UUID; `referenceId`
/// queda disponible para cuando haga falta navegar/deep-link a una categoría puntual.
class Category {
  const Category({
    required this.id,
    required this.referenceId,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    this.parentCategoryId,
  });

  final int id;
  final String referenceId;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final int? parentCategoryId;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      parentCategoryId: json['parentCategoryId'] as int?,
    );
  }
}
