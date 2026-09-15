import 'contract_status.dart';

part 'contract.g.dart';
part 'contract_content_snapshot.g.dart';
part 'my_contract_summary.g.dart';

/// Ítem congelado dentro del `contentSnapshot` — nunca se relee `BudgetLineItems` en vivo.
class ContractLineItemSnapshot {
  const ContractLineItemSnapshot({
    required this.itemType,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.catalogItemName,
  });

  final String itemType;
  final String? catalogItemName;
  final String description;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  factory ContractLineItemSnapshot.fromJson(Map<String, dynamic> json) {
    return ContractLineItemSnapshot(
      itemType: json['itemType'] as String,
      catalogItemName: json['catalogItemName'] as String?,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }
}

class ContractServiceSnapshot {
  const ContractServiceSnapshot({
    required this.title,
    required this.description,
    required this.categoryName,
  });

  final String title;
  final String description;
  final String categoryName;

  factory ContractServiceSnapshot.fromJson(Map<String, dynamic> json) {
    return ContractServiceSnapshot(
      title: json['title'] as String,
      description: json['description'] as String,
      categoryName: json['categoryName'] as String,
    );
  }
}

class ContractBudgetOptionSnapshot {
  const ContractBudgetOptionSnapshot({
    required this.label,
    required this.totalPrice,
    this.description,
    this.estimatedHours,
  });

  final String label;
  final String? description;
  final double totalPrice;
  final double? estimatedHours;

  factory ContractBudgetOptionSnapshot.fromJson(Map<String, dynamic> json) {
    return ContractBudgetOptionSnapshot(
      label: json['label'] as String,
      description: json['description'] as String?,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
    );
  }
}

class ContractContentSnapshot {
  const ContractContentSnapshot({
    required this.service,
    required this.budgetOption,
    required this.lineItems,
  });

  final ContractServiceSnapshot service;
  final ContractBudgetOptionSnapshot budgetOption;
  final List<ContractLineItemSnapshot> lineItems;

  /// `fromJson` generado por `dart run tool/openapi_codegen/generate_model.dart` (M-04, ver
  /// `openspec/changes/platform-hardening-2026-09/CODEGEN.md`) — regenerar con:
  /// ```
  /// dart run tool/openapi_codegen/generate_model.dart \
  ///   --schema ContractContentSnapshotDTO --class ContractContentSnapshot \
  ///   --openapi-url <backend>/tekoapp-backend/api/swagger-json \
  ///   --out lib/features/contracts/models/contract_content_snapshot.g.dart \
  ///   --part contract.dart \
  ///   --ref-fields service:ContractServiceSnapshot,budgetOption:ContractBudgetOptionSnapshot,lineItems:ContractLineItemSnapshot
  /// ```
  /// `lineItems` es el primer array de objetos anidados que migra a codegen — ver la extensión
  /// del generador que esto motivó en el mismo commit que agregó soporte para arrays de `$ref`.
  factory ContractContentSnapshot.fromJson(Map<String, dynamic> json) =>
      _$ContractContentSnapshotFromJson(json);
}

class LegalTermsVersionSummary {
  const LegalTermsVersionSummary({
    required this.referenceId,
    required this.version,
    required this.contentUrl,
  });

  final String referenceId;
  final String version;
  final String contentUrl;

  factory LegalTermsVersionSummary.fromJson(Map<String, dynamic> json) {
    return LegalTermsVersionSummary(
      referenceId: json['referenceId'] as String,
      version: json['version'] as String,
      contentUrl: json['contentUrl'] as String,
    );
  }
}

/// `Contracts` — ver `openspec/specs/service-contracts.md`. El mecanismo de firma es un registro
/// de aceptación electrónica reforzado, NO una firma digital calificada (eIDAS/PKI) — la copy de
/// la UI debe reflejarlo con precisión, ver `ContractPreviewScreen`.
enum ContractViewerRole {
  client,
  professional;

  factory ContractViewerRole.fromJson(String value) {
    return switch (value) {
      'CLIENT' => ContractViewerRole.client,
      'PROFESSIONAL' => ContractViewerRole.professional,
      _ => throw ArgumentError('ContractViewerRole desconocido: $value'),
    };
  }
}

class Contract {
  const Contract({
    required this.referenceId,
    required this.status,
    required this.viewerRole,
    required this.contentSnapshot,
    required this.pdfAvailable,
    this.legalTermsVersion,
    this.clientSignedAt,
    this.professionalSignedAt,
  });

  final String referenceId;
  final ContractStatus status;
  final ContractViewerRole viewerRole;
  final ContractContentSnapshot contentSnapshot;
  final LegalTermsVersionSummary? legalTermsVersion;
  final DateTime? clientSignedAt;
  final DateTime? professionalSignedAt;
  final bool pdfAvailable;

  /// "Me toca firmar" — sin importar el rol, sigue siendo `false` una vez firmado por ambos.
  bool get isPendingViewerSignature => switch ((viewerRole, status)) {
        (ContractViewerRole.client, ContractStatus.pendingClientSignature) =>
          true,
        (
          ContractViewerRole.professional,
          ContractStatus.pendingProfessionalSignature
        ) =>
          true,
        _ => false,
      };

  /// `fromJson` generado por `dart run tool/openapi_codegen/generate_model.dart` (M-04, ver
  /// `openspec/changes/platform-hardening-2026-09/CODEGEN.md`) — regenerar con:
  /// ```
  /// dart run tool/openapi_codegen/generate_model.dart \
  ///   --schema ContractResponseDTO --class Contract \
  ///   --openapi-url <backend>/tekoapp-backend/api/swagger-json \
  ///   --out lib/features/contracts/models/contract.g.dart \
  ///   --part contract.dart \
  ///   --enum-fields status:ContractStatus,viewerRole:ContractViewerRole \
  ///   --ref-fields contentSnapshot:ContractContentSnapshot,legalTermsVersion:LegalTermsVersionSummary
  /// ```
  factory Contract.fromJson(Map<String, dynamic> json) =>
      _$ContractFromJson(json);
}

/// Fila de `GET /contracts` (listado propio) — resumen liviano, sin el snapshot completo.
class MyContractSummary {
  const MyContractSummary({
    required this.referenceId,
    required this.status,
    required this.serviceTitle,
    required this.createdAt,
    required this.pdfAvailable,
  });

  final String referenceId;
  final ContractStatus status;
  final String serviceTitle;
  final DateTime createdAt;
  final bool pdfAvailable;

  /// `fromJson` generado por `dart run tool/openapi_codegen/generate_model.dart` (M-04, ver
  /// `openspec/changes/platform-hardening-2026-09/CODEGEN.md`) — regenerar con:
  /// ```
  /// dart run tool/openapi_codegen/generate_model.dart \
  ///   --schema MyContractSummaryResponseDTO --class MyContractSummary \
  ///   --openapi-url <backend>/tekoapp-backend/api/swagger-json \
  ///   --out lib/features/contracts/models/my_contract_summary.g.dart \
  ///   --part contract.dart \
  ///   --enum-fields status:ContractStatus
  /// ```
  factory MyContractSummary.fromJson(Map<String, dynamic> json) =>
      _$MyContractSummaryFromJson(json);
}
