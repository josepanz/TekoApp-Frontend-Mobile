// GENERADO por `dart run tool/openapi_codegen/generate_model.dart` desde "ContractResponseDTO" — no editar a mano.
// Si este archivo difiere de lo commiteado tras regenerar, el contrato del backend
// cambió sin que el modelo se actualizara (ver M-04, openspec/changes/platform-hardening-2026-09/CODEGEN.md).
part of 'contract.dart';

Contract _$ContractFromJson(Map<String, dynamic> json) => Contract(
      referenceId: json['referenceId'] as String,
      status: ContractStatus.fromJson(json['status'] as String),
      viewerRole: ContractViewerRole.fromJson(json['viewerRole'] as String),
      contentSnapshot: ContractContentSnapshot.fromJson(
          json['contentSnapshot'] as Map<String, dynamic>),
      legalTermsVersion: json['legalTermsVersion'] == null
          ? null
          : LegalTermsVersionSummary.fromJson(
              json['legalTermsVersion'] as Map<String, dynamic>),
      clientSignedAt: json['clientSignedAt'] == null
          ? null
          : DateTime.parse(json['clientSignedAt'] as String),
      professionalSignedAt: json['professionalSignedAt'] == null
          ? null
          : DateTime.parse(json['professionalSignedAt'] as String),
      pdfAvailable: json['pdfAvailable'] as bool,
    );
