import 'promotion_status.dart';
import 'promotion_type.dart';

part 'promotion.g.dart';

/// `PromotionDetailResponseDTO` — el detalle completo de una promoción, embebido en
/// `PromotionValidation`/`PromotionApplyResult`.
///
/// **Hallazgo real de la migración a codegen (M-04)**: el modelo a mano solo exponía `code` y
/// `name` — el backend siempre devuelve, y el modelo descartaba en silencio, otros 16 campos:
/// `id`, `description`, `type`, `status`, `discountPercentage`, `discountAmount`,
/// `minimumAmount`, `maximumDiscount`, `maxUsage`, `maxUsagePerUser`, `currentUsage`,
/// `validFrom`, `validUntil`, `allowedUserTypes`, `specificUserIds`, `createdById`, `createdAt`,
/// `lastChangedAt`. Es el hallazgo de mayor alcance de todos los dominios migrados hasta ahora —
/// consistente con que `promotions` es, junto a `payments`, el dominio que más directamente
/// mueve el monto final que paga un cliente.
///
/// **Ninguno de los campos nuevos tiene consumidor en la UI todavía** (mismo criterio que
/// `ratings`/`professional_profile`) — se exponen para que la próxima pantalla que necesite
/// mostrar detalle de promoción (vigencia, tope de descuento, etc.) no tenga que volver a tocar
/// el modelo primero.
///
/// `fromJson` generado por `dart run tool/openapi_codegen/generate_model.dart` — regenerar con:
/// ```
/// dart run tool/openapi_codegen/generate_model.dart \
///   --schema PromotionDetailResponseDTO --class Promotion \
///   --openapi-url <backend>/tekoapp-backend/api/swagger-json \
///   --out lib/features/promotions/models/promotion.g.dart \
///   --part promotion.dart \
///   --int-fields maxUsage,maxUsagePerUser,currentUsage,createdById,specificUserIds \
///   --enum-fields type:PromotionType,status:PromotionStatus
/// ```
class Promotion {
  const Promotion({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.status,
    required this.maxUsage,
    required this.maxUsagePerUser,
    required this.currentUsage,
    required this.validFrom,
    required this.validUntil,
    required this.allowedUserTypes,
    required this.specificUserIds,
    required this.createdAt,
    this.description,
    this.discountPercentage,
    this.discountAmount,
    this.minimumAmount,
    this.maximumDiscount,
    this.createdById,
    this.lastChangedAt,
  });

  /// Ojo: pese al nombre, el backend expone acá la UUID pública (no un `id` interno numérico) —
  /// así lo declara `PromotionDetailResponseDTO.id` (inconsistente con la convención
  /// `referenceId` que usa el resto del backend, no es una decisión de este modelo).
  final String id;
  final String code;
  final String name;
  final String? description;
  final PromotionType type;
  final PromotionStatus status;

  /// Solo aplica si [type] es `percentage`.
  final double? discountPercentage;

  /// Solo aplica si [type] es `fixedAmount`.
  final double? discountAmount;
  final double? minimumAmount;
  final double? maximumDiscount;

  /// `-1` = ilimitado.
  final int maxUsage;
  final int maxUsagePerUser;
  final int currentUsage;
  final DateTime validFrom;
  final DateTime validUntil;
  final List<String> allowedUserTypes;

  /// IDs internos de `Users` (no `referenceId`) — el backend los usa para restringir la
  /// promoción a usuarios puntuales; sin consumidor en la UI, se expone tal cual llega.
  final List<int> specificUserIds;
  final int? createdById;
  final DateTime createdAt;
  final DateTime? lastChangedAt;

  factory Promotion.fromJson(Map<String, dynamic> json) =>
      _$PromotionFromJson(json);
}
