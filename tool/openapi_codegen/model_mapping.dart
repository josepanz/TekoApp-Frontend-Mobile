// Mapeo modelo↔schema para `dart run tool/openapi_codegen/check_drift.dart` — ver
// openspec/changes/platform-hardening-2026-09/CODEGEN.md para el diseño completo y "Cómo agregar
// un modelo nuevo" para instrucciones paso a paso.
//
// Este archivo es la ÚNICA fuente de verdad de qué clase Dart corresponde a qué schema de
// OpenAPI — los nombres no siempre coinciden (ver `renameFields` más abajo), así que hace falta
// declararlo a mano. Un modelo que no aparece acá ni en `localModelExemptions` hace fallar el
// chequeo de cobertura del verificador ("SIN REGISTRAR").
//
// Las clases `FieldExemption`/`LocalModelExemption` piden `reason` como parámetro NOMBRADO
// REQUERIDO — no hay forma de construir una exención sin motivo, ni siquiera con un valor vacío
// (el constructor lo valida en runtime). Esto es a propósito: una exención sin motivo escrito no
// se acepta.

/// Un campo de un schema que a propósito NO se mapea a ningún campo del modelo Dart (el schema lo
/// tiene, el modelo lo omite deliberadamente) — o, con `side: ExemptionSide.model`, un campo del
/// modelo Dart que a propósito no viene de este schema.
class FieldExemption {
  FieldExemption({
    required this.field,
    required this.reason,
    this.side = ExemptionSide.schema,
  }) {
    if (reason.trim().length < 8) {
      throw ArgumentError(
        'La exención del campo "$field" necesita un motivo real (mínimo 8 caracteres), '
        'no un placeholder.',
      );
    }
  }

  /// Nombre del campo — del lado del schema si `side == schema`, del lado del modelo Dart si
  /// `side == model`.
  final String field;
  final String reason;
  final ExemptionSide side;
}

enum ExemptionSide { schema, model }

/// Un modelo Dart (clase o enum) que NO corresponde a ningún schema del backend — estado local de
/// UI, un enum sin schema propio en swagger, una jerarquía de errores de dominio, etc. Si
/// `className` es `null`, la exención cubre TODAS las clases/enums declarados en `dartFile`
/// (útil para archivos enteramente locales, como una jerarquía `sealed class XFailure`).
class LocalModelExemption {
  LocalModelExemption({
    required this.dartFile,
    this.className,
    required this.reason,
  }) {
    if (reason.trim().length < 8) {
      throw ArgumentError(
        'La exención de "$dartFile"${className != null ? '.$className' : ''} necesita un '
        'motivo real (mínimo 8 caracteres), no un placeholder.',
      );
    }
  }

  final String dartFile;
  final String? className;
  final String reason;
}

/// Mapeo de UNA clase Dart a UN schema de `components.schemas`.
class ModelMapping {
  const ModelMapping({
    required this.dartFile,
    required this.className,
    required this.schemaName,
    this.renameFields = const {},
    this.schemaFieldExemptions = const [],
    this.modelFieldExemptions = const [],
  });

  /// Ruta relativa a la raíz del repo (`lib/features/.../models/archivo.dart`).
  final String dartFile;

  /// Nombre de la clase Dart dentro de `dartFile`.
  final String className;

  /// Nombre del schema en `components.schemas.<Nombre>`.
  final String schemaName;

  /// Clave del JSON (nombre en el schema) -> nombre del parámetro/campo Dart, para los pocos
  /// casos donde no coinciden (mismo concepto que `--rename-fields` del generador, ver
  /// `Service.client` <- `ServiceDetailResponseDTO.users`).
  final Map<String, String> renameFields;

  /// Campos del SCHEMA que a propósito no tienen contraparte en el modelo Dart.
  final List<FieldExemption> schemaFieldExemptions;

  /// Campos del MODELO DART que a propósito no vienen de este schema.
  final List<FieldExemption> modelFieldExemptions;
}

/// Modelos mapeados a un schema real — el verificador compara cada uno campo a campo.
final List<ModelMapping> modelMappings = [
  // ---- ai_disclosures ----
  const ModelMapping(
    dartFile: 'lib/features/ai_disclosures/models/ai_disclosure.dart',
    className: 'AiDisclosure',
    schemaName: 'AiDisclosureResponseDTO',
  ),

  // ---- auth ----
  ModelMapping(
    dartFile: 'lib/features/auth/models/login_result.dart',
    className: 'LoginResult',
    schemaName: 'LoginUserResponseDTO',
    schemaFieldExemptions: [
      FieldExemption(
        field: 'refreshToken',
        reason:
            'nunca viaja en el body de la respuesta, solo como cookie httpOnly (ver '
            'openspec/decisions.md) — el modelo lo omite a propósito.',
      ),
    ],
  ),
  const ModelMapping(
    dartFile: 'lib/features/auth/models/register_result.dart',
    className: 'RegisterResult',
    schemaName: 'OnboardingUserResponseDTO',
  ),

  // ---- budgets ----
  const ModelMapping(
    dartFile: 'lib/features/budgets/models/budget_line_item.dart',
    className: 'BudgetLineItem',
    schemaName: 'BudgetLineItemResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/budgets/models/budget_option.dart',
    className: 'BudgetOption',
    schemaName: 'BudgetOptionResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/budgets/models/material_catalog_item.dart',
    className: 'MaterialCatalogItem',
    schemaName: 'MaterialCatalogItemResponseDTO',
  ),

  // ---- categories ----
  const ModelMapping(
    dartFile: 'lib/features/categories/models/category.dart',
    className: 'Category',
    schemaName: 'CategoryDetailResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/categories/models/service_type.dart',
    className: 'ServiceType',
    schemaName: 'ServiceTypeResponseDTO',
  ),

  // ---- contracts (Contract/MyContractSummary/ContractContentSnapshot ya migrados a codegen,
  // M-04 §7.3 — las hojas hand-written referenciadas vía --ref-fields se registran acá por
  // primera vez) ----
  const ModelMapping(
    dartFile: 'lib/features/contracts/models/contract.dart',
    className: 'Contract',
    schemaName: 'ContractResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/contracts/models/contract.dart',
    className: 'MyContractSummary',
    schemaName: 'MyContractSummaryResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/contracts/models/contract.dart',
    className: 'ContractContentSnapshot',
    schemaName: 'ContractContentSnapshotDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/contracts/models/contract.dart',
    className: 'ContractServiceSnapshot',
    schemaName: 'ContractServiceSnapshotDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/contracts/models/contract.dart',
    className: 'ContractBudgetOptionSnapshot',
    schemaName: 'ContractBudgetOptionSnapshotDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/contracts/models/contract.dart',
    className: 'ContractLineItemSnapshot',
    schemaName: 'ContractLineItemSnapshotDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/contracts/models/contract.dart',
    className: 'LegalTermsVersionSummary',
    schemaName: 'LegalTermsVersionSummaryDTO',
  ),

  // ---- legal_consents ----
  const ModelMapping(
    dartFile: 'lib/features/legal_consents/models/content_consent_grant.dart',
    className: 'ContentConsentGrant',
    schemaName: 'ContentConsentGrantResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/legal_consents/models/data_consents_history.dart',
    className: 'DataConsentsHistory',
    schemaName: 'DataConsentsHistoryResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/legal_consents/models/legal_document_version.dart',
    className: 'LegalDocumentVersion',
    schemaName: 'LegalDocumentVersionResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/legal_consents/models/user_consent.dart',
    className: 'UserConsent',
    schemaName: 'UserConsentResponseDTO',
  ),

  // ---- locations ----
  const ModelMapping(
    dartFile: 'lib/features/locations/models/nearby_professional.dart',
    className: 'NearbyProfessional',
    schemaName: 'NearbyProfessionalResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/locations/models/professional_last_location.dart',
    className: 'ProfessionalLastLocation',
    schemaName: 'ProfessionalLocationResponseDTO',
  ),

  // ---- payments ----
  const ModelMapping(
    dartFile: 'lib/features/payments/models/payment.dart',
    className: 'Payment',
    schemaName: 'PaymentDetailResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/payments/models/payment_method.dart',
    className: 'PaymentMethod',
    schemaName: 'PaymentMethodDetailResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/payments/models/tip.dart',
    className: 'Tip',
    schemaName: 'TipResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/payments/models/tip.dart',
    className: 'TipConfig',
    schemaName: 'TipConfigResponseDTO',
  ),

  // ---- professional_documents ----
  const ModelMapping(
    dartFile:
        'lib/features/professional_documents/models/my_document_status.dart',
    className: 'MyDocumentStatus',
    schemaName: 'MyDocumentStatusResponseDTO',
  ),
  const ModelMapping(
    dartFile:
        'lib/features/professional_documents/models/professional_document.dart',
    className: 'ProfessionalDocument',
    schemaName: 'ProfessionalDocumentResponseDTO',
  ),
  const ModelMapping(
    dartFile:
        'lib/features/professional_documents/models/professional_document_type.dart',
    className: 'ProfessionalDocumentType',
    schemaName: 'ProfessionalDocumentTypeResponseDTO',
  ),

  // ---- professional_portfolio ----
  const ModelMapping(
    dartFile: 'lib/features/professional_portfolio/models/portfolio_item.dart',
    className: 'PortfolioItem',
    schemaName: 'PortfolioItemResponseDTO',
  ),

  // ---- professional_profile ----
  const ModelMapping(
    dartFile:
        'lib/features/professional_profile/models/professional_profile.dart',
    className: 'ProfessionalUserSummary',
    schemaName: 'UserSummaryResponseDTO',
  ),
  const ModelMapping(
    dartFile:
        'lib/features/professional_profile/models/professional_profile.dart',
    className: 'ProfessionalCategorySummary',
    schemaName: 'CategorySummaryResponseDTO',
  ),
  const ModelMapping(
    dartFile:
        'lib/features/professional_profile/models/professional_profile.dart',
    className: 'ProfessionalProfile',
    schemaName: 'ProfessionalDetailResponseDTO',
  ),

  // ---- promotions ----
  const ModelMapping(
    dartFile: 'lib/features/promotions/models/promotion.dart',
    className: 'Promotion',
    schemaName: 'PromotionDetailResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/promotions/models/promotion_apply_result.dart',
    className: 'PromotionApplyResult',
    schemaName: 'PromotionApplyResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/promotions/models/promotion_validation.dart',
    className: 'PromotionValidation',
    schemaName: 'PromotionValidateResponseDTO',
  ),

  // ---- ratings ----
  const ModelMapping(
    dartFile: 'lib/features/ratings/models/professional_rating_stats.dart',
    className: 'ProfessionalRatingStats',
    schemaName: 'ProfessionalRatingStatsResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/ratings/models/rating.dart',
    className: 'Rating',
    schemaName: 'RatingDetailResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/ratings/models/user_rating_stats.dart',
    className: 'UserRatingStats',
    schemaName: 'UserRatingStatsResponseDTO',
  ),

  // ---- service_progress ----
  const ModelMapping(
    dartFile:
        'lib/features/service_progress/models/service_progress_entry.dart',
    className: 'ServiceProgressEntry',
    schemaName: 'ServiceProgressEntryResponseDTO',
  ),

  // ---- services ----
  const ModelMapping(
    dartFile: 'lib/features/services/models/service.dart',
    className: 'ServiceCategorySummary',
    schemaName: 'ServiceCategorySummaryResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/services/models/service.dart',
    className: 'ServiceClientSummary',
    schemaName: 'ServiceUserSummaryResponseDTO',
  ),
  const ModelMapping(
    dartFile: 'lib/features/services/models/service.dart',
    className: 'Service',
    schemaName: 'ServiceDetailResponseDTO',
    renameFields: {'users': 'client'},
  ),
  const ModelMapping(
    dartFile: 'lib/features/services/models/service_request.dart',
    className: 'ServiceRequest',
    schemaName: 'ServiceRequestDetailResponseDTO',
  ),
];

/// Modelos/campos que a propósito quedan fuera del chequeo campo a campo — cada uno con su
/// motivo. Ver "Cómo declarar una exención" en CODEGEN.md.
final List<LocalModelExemption> localModelExemptions = [
  // ---- account_deletion ----
  LocalModelExemption(
    dartFile:
        'lib/features/account_deletion/models/account_deletion_failure.dart',
    reason:
        'jerarquía sealed de errores de dominio (Exception) — ninguna subclase corresponde a '
        'un schema de respuesta del backend.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/account_deletion/models/deletion_blocker.dart',
    reason:
        'DeletionBlockerType es un enum espejo sin schema propio en swagger (los valores de '
        'enum inline no generan un components.schemas separado); DeletionBlocker es el cuerpo '
        'del error 409 DELETION_BLOCKED, que NestJS/swagger no documenta como schema (no es una '
        'respuesta 2xx). Confirmado: no existe un schema "DeletionBlocker*" en el swagger real.',
  ),

  // ---- ai_disclosures ----
  LocalModelExemption(
    dartFile: 'lib/features/ai_disclosures/models/ai_disclosure_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/ai_disclosures/models/ai_disclosure_source.dart',
    reason:
        'enum espejo de Prisma — sus valores viven inline en la propiedad "source" de '
        'AiDisclosureResponseDTO, no como schema propio. Comparar valores de enum contra el '
        'swagger queda fuera de alcance del verificador v1 (ver CODEGEN.md).',
  ),

  // ---- auth ----
  LocalModelExemption(
    dartFile: 'lib/features/auth/models/login_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/auth/models/register_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/auth/models/scope_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),

  // ---- budgets ----
  LocalModelExemption(
    dartFile: 'lib/features/budgets/models/budget_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/budgets/models/budget_option.dart',
    className: 'BudgetLineItemDraft',
    reason:
        'estado local del armado de un ítem todavía sin enviar (ver docstring de la clase) — '
        'no existe como respuesta del backend, solo como borrador de UI antes del PUT.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/budgets/models/budget_option.dart',
    className: 'BudgetOptionDraft',
    reason:
        'estado local del armado de una opción todavía sin enviar (ver docstring de la '
        'clase) — no existe como respuesta del backend.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/budgets/models/budget_line_item_type.dart',
    reason:
        'enum espejo — sus valores viven inline en las propiedades que lo referencian '
        '(BudgetLineItemResponseDTO.itemType), no como schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/budgets/models/material_quality_tier.dart',
    reason:
        'enum espejo, valores inline en MaterialCatalogItemResponseDTO.qualityTier.',
  ),

  // ---- contracts ----
  LocalModelExemption(
    dartFile: 'lib/features/contracts/models/contract.dart',
    className: 'ContractViewerRole',
    reason:
        'enum local (rol de quien mira el contrato, "client"/"professional") derivado por el '
        'propio Mobile a partir de la sesión, no un campo que el backend exponga en el DTO.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/contracts/models/contract_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/contracts/models/contract_status.dart',
    reason: 'enum espejo, valores inline en ContractResponseDTO.status.',
  ),

  // ---- legal_consents ----
  LocalModelExemption(
    dartFile:
        'lib/features/legal_consents/models/ai_disclosure_entity_type.dart',
    reason:
        'enum espejo, valores inline en ContentConsentGrantResponseDTO.contentType/'
        'AiDisclosureResponseDTO.entityType.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/legal_consents/models/content_usage_scope.dart',
    reason:
        'enum espejo, valores inline en ContentConsentGrantResponseDTO.usageScope.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/legal_consents/models/legal_consents_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/legal_consents/models/legal_document_type.dart',
    reason:
        'enum espejo, valores inline en LegalDocumentVersionResponseDTO.documentType. NOTA '
        '2026-09-12: el swagger real ya lista 6 valores ("SERVICE_CONTRACT_TERMS", '
        '"USER_CONTENT_LIABILITY_DISCLAIMER" agregados) contra los 4 que cubre este enum Dart — '
        'hallazgo manual al construir este mapeo, no detectado por el verificador v1 (no compara '
        'valores de enum, ver CODEGEN.md); queda para que José decida si migrar el enum.',
  ),

  // ---- locations ----
  LocalModelExemption(
    dartFile: 'lib/features/locations/models/locations_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),

  // ---- notifications ----
  LocalModelExemption(
    dartFile: 'lib/features/notifications/models/device_type.dart',
    reason:
        'enum espejo, valores inline en CreateFcmTokenRequestDTO/FcmTokenResponseDTO.deviceType.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/notifications/models/notifications_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile:
        'lib/features/notifications/models/push_notification_payload.dart',
    reason:
        'no viene del swagger: se construye desde RemoteMessage.data de Firebase Cloud '
        'Messaging (formato ad-hoc de FCM, siempre strings planos), no de un DTO HTTP '
        'documentado.',
  ),

  // ---- payments ----
  LocalModelExemption(
    dartFile: 'lib/features/payments/models/payment_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/payments/models/payment_method.dart',
    className: 'PaymentMethodType',
    reason:
        'enum espejo, valores inline en PaymentMethodDetailResponseDTO.type.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/payments/models/payment_method.dart',
    className: 'PaymentProviderType',
    reason:
        'enum espejo, valores inline en PaymentMethodDetailResponseDTO.provider.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/payments/models/payment_status.dart',
    reason: 'enum espejo, valores inline en PaymentDetailResponseDTO.status.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/payments/models/tip_mode.dart',
    reason: 'enum espejo, valores inline en TipResponseDTO.mode.',
  ),

  // ---- professional_documents ----
  LocalModelExemption(
    dartFile:
        'lib/features/professional_documents/models/document_category.dart',
    reason:
        'enum espejo, valores inline en ProfessionalDocumentTypeResponseDTO.category.',
  ),
  LocalModelExemption(
    dartFile:
        'lib/features/professional_documents/models/document_review_status.dart',
    reason:
        'enum espejo, valores inline en ProfessionalDocumentResponseDTO.status.',
  ),
  LocalModelExemption(
    dartFile:
        'lib/features/professional_documents/models/professional_document_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),

  // ---- professional_portfolio ----
  LocalModelExemption(
    dartFile:
        'lib/features/professional_portfolio/models/portfolio_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile:
        'lib/features/professional_portfolio/models/portfolio_review_status.dart',
    reason: 'enum espejo, valores inline en PortfolioItemResponseDTO.status.',
  ),

  // ---- professional_profile ----
  LocalModelExemption(
    dartFile:
        'lib/features/professional_profile/models/professional_profile_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile:
        'lib/features/professional_profile/models/professional_status.dart',
    reason:
        'enum espejo, valores inline en ProfessionalDetailResponseDTO.status.',
  ),

  // ---- profile ----
  LocalModelExemption(
    dartFile: 'lib/features/profile/models/profile_failure.dart',
    reason:
        'dos jerarquías sealed de errores de dominio (ProfileFailure, AvatarUploadFailure), '
        'ninguna corresponde a un schema de respuesta.',
  ),

  // ---- promotions ----
  LocalModelExemption(
    dartFile: 'lib/features/promotions/models/promotion_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/promotions/models/promotion_status.dart',
    reason: 'enum espejo, valores inline en PromotionDetailResponseDTO.status.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/promotions/models/promotion_type.dart',
    reason: 'enum espejo, valores inline en PromotionDetailResponseDTO.type.',
  ),

  // ---- ratings ----
  LocalModelExemption(
    dartFile: 'lib/features/ratings/models/rating_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/ratings/models/rating_type.dart',
    reason: 'enum espejo, valores inline en RatingDetailResponseDTO.type.',
  ),

  // ---- service_progress ----
  LocalModelExemption(
    dartFile:
        'lib/features/service_progress/models/service_progress_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),

  // ---- services ----
  LocalModelExemption(
    dartFile: 'lib/features/services/models/request_status.dart',
    reason:
        'enum espejo, valores inline en ServiceRequestDetailResponseDTO.status.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/services/models/service_failure.dart',
    reason: 'jerarquía sealed de errores de dominio, sin schema propio.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/services/models/service_status.dart',
    reason: 'enum espejo, valores inline en ServiceDetailResponseDTO.status.',
  ),
  LocalModelExemption(
    dartFile: 'lib/features/services/models/service.dart',
    className: 'ServiceProfessionalSummary',
    reason:
        'aplana ServiceProfessionalSummaryResponseDTO.user.firstName/lastName (objeto anidado) '
        'a campos de nivel superior en el fromJson a mano — no es un mapeo 1:1 con las '
        'propiedades de nivel superior del schema, y el verificador de campos v1 no representa '
        'aplanados. Confirmado contra el schema real: firstName/lastName viven bajo .user, no '
        'en la raíz.',
  ),
];
