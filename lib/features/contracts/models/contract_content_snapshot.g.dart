// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "ContractContentSnapshotDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'contract.dart';

ContractContentSnapshot _$ContractContentSnapshotFromJson(
        Map<String, dynamic> json) =>
    ContractContentSnapshot(
      service: ContractServiceSnapshot.fromJson(
          json['service'] as Map<String, dynamic>),
      budgetOption: ContractBudgetOptionSnapshot.fromJson(
          json['budgetOption'] as Map<String, dynamic>),
      lineItems: (json['lineItems'] as List<dynamic>)
          .map((e) =>
              ContractLineItemSnapshot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
