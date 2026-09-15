// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "MyContractSummaryResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'contract.dart';

MyContractSummary _$MyContractSummaryFromJson(Map<String, dynamic> json) =>
    MyContractSummary(
      referenceId: json['referenceId'] as String,
      status: ContractStatus.fromJson(json['status'] as String),
      serviceTitle: json['serviceTitle'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      pdfAvailable: json['pdfAvailable'] as bool,
    );
