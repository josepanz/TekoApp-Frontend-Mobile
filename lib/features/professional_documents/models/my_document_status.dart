import 'professional_document.dart';
import 'professional_document_type.dart';

/// `MyDocumentStatusResponseDTO` — un tipo aplicable a mi categoría, con mi documento más
/// reciente si ya cargué alguno (`document == null` → todavía no cargué nada de este tipo).
class MyDocumentStatus {
  const MyDocumentStatus({required this.documentType, this.document});

  final ProfessionalDocumentType documentType;
  final ProfessionalDocument? document;

  factory MyDocumentStatus.fromJson(Map<String, dynamic> json) {
    return MyDocumentStatus(
      documentType: ProfessionalDocumentType.fromJson(
        json['documentType'] as Map<String, dynamic>,
      ),
      document: json['document'] != null
          ? ProfessionalDocument.fromJson(
              json['document'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
