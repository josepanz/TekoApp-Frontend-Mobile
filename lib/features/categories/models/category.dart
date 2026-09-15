/// Estado de una categoría — mismo enum `CategoryStatus` de `TekoApp-Backend`
/// (`prisma/schema.prisma`).
enum CategoryStatus {
  active,
  inactive,
  pending;

  factory CategoryStatus.fromJson(String value) {
    return switch (value) {
      'ACTIVE' => CategoryStatus.active,
      'INACTIVE' => CategoryStatus.inactive,
      'PENDING' => CategoryStatus.pending,
      _ => throw ArgumentError('CategoryStatus desconocido: $value'),
    };
  }

  String toJson() {
    return switch (this) {
      CategoryStatus.active => 'ACTIVE',
      CategoryStatus.inactive => 'INACTIVE',
      CategoryStatus.pending => 'PENDING',
    };
  }
}

/// Categoría del catálogo de servicios (`GET /categories`, listado público filtrado
/// activo+visible — ver `openspec/specs/services-marketplace.md`).
///
/// A diferencia de `Services`/`ServiceRequests`, el backend expone acá AMBOS identificadores por
/// separado (`id` Int interno y `referenceId` UUID público) — ver `openspec/decisions.md`. Se
/// conserva `id` porque `POST /services` pide `categoryId` como Int, no como UUID; `referenceId`
/// queda disponible para cuando haga falta navegar/deep-link a una categoría puntual.
///
/// `status`/`isVisible` viajan siempre (M-04, verificador de drift) pero NO se filtran acá: el
/// único endpoint que Mobile consume para listar categorías (`GET /categories`, ver
/// `CategoriesRepository.fetchCategories`) ya filtra `status: ACTIVE, isVisible: true` del lado
/// del backend (`CategoriesService.findAll`, `TekoApp-Backend/src/api/categories/services/categories.service.ts`) —
/// filtrar de nuevo acá sería redundante. Se exponen para que un consumidor futuro que use un
/// endpoint distinto (`/categories/all`, sin ese filtro) no tenga que volver a tocar el modelo.
class Category {
  const Category({
    required this.id,
    required this.referenceId,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.color,
    required this.sortOrder,
    required this.status,
    required this.isVisible,
    required this.requiresVerification,
    required this.maxBudgetOptionsPerRequest,
    this.metadata,
    this.parentCategoryId,
    required this.createdAt,
    this.lastChangedAt,
  });

  final int id;
  final String referenceId;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String? color;
  final int sortOrder;
  final CategoryStatus status;
  final bool isVisible;
  final bool requiresVerification;
  final int maxBudgetOptionsPerRequest;
  final Map<String, dynamic>? metadata;
  final int? parentCategoryId;
  final DateTime createdAt;
  final DateTime? lastChangedAt;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      referenceId: json['referenceId'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      sortOrder: json['sortOrder'] as int,
      status: CategoryStatus.fromJson(json['status'] as String),
      isVisible: json['isVisible'] as bool,
      requiresVerification: json['requiresVerification'] as bool,
      maxBudgetOptionsPerRequest: json['maxBudgetOptionsPerRequest'] as int,
      metadata: json['metadata'] as Map<String, dynamic>?,
      parentCategoryId: json['parentCategoryId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastChangedAt: json['lastChangedAt'] == null
          ? null
          : DateTime.parse(json['lastChangedAt'] as String),
    );
  }
}
