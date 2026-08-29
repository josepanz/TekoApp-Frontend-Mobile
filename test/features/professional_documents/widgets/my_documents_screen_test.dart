import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/document_category.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/document_review_status.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/my_document_status.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document.dart';
import 'package:tekoapp_mobile/features/professional_documents/models/professional_document_type.dart';
import 'package:tekoapp_mobile/features/professional_documents/providers/my_documents_provider.dart';
import 'package:tekoapp_mobile/features/professional_documents/widgets/my_documents_screen.dart';
import 'package:tekoapp_mobile/l10n/app_localizations.dart';

ProfessionalDocumentType _type({
  String referenceId = 'type-1',
  bool isRequired = true,
}) {
  return ProfessionalDocumentType(
    referenceId: referenceId,
    code: 'BG_CHECK',
    name: 'Antecedentes policiales',
    category: DocumentCategory.backgroundCheck,
    isRequired: isRequired,
    requiresStaffReview: true,
    isVisibleToClient: false,
    sortOrder: 0,
    isActive: true,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required List<MyDocumentStatus> statuses,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myDocumentsProvider.overrideWith((ref) async => statuses),
      ],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MyDocumentsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el estado vacío cuando no hay tipos aplicables', (
    tester,
  ) async {
    // Arrange & Act
    await _pump(tester, statuses: []);

    // Assert
    expect(
      find.text('Todavía no hay tipos de documento configurados para tu categoría'),
      findsOneWidget,
    );
  });

  testWidgets('muestra "Sin cargar" y el botón Subir cuando no hay documento', (
    tester,
  ) async {
    // Arrange & Act
    await _pump(
      tester,
      statuses: [MyDocumentStatus(documentType: _type())],
    );

    // Assert
    expect(find.text('Sin cargar'), findsOneWidget);
    expect(find.text('Subir'), findsOneWidget);
  });

  testWidgets('muestra "Aprobado" sin botón de subida cuando ya está aprobado', (
    tester,
  ) async {
    // Arrange
    final document = ProfessionalDocument(
      referenceId: 'doc-1',
      professionalDocumentType: _type(),
      fileKey: 'abc.jpg',
      status: DocumentReviewStatus.approved,
      createdAt: DateTime.utc(2026, 8, 27),
    );

    // Act
    await _pump(
      tester,
      statuses: [MyDocumentStatus(documentType: _type(), document: document)],
    );

    // Assert
    expect(find.text('Aprobado'), findsOneWidget);
    expect(find.text('Subir'), findsNothing);
    expect(find.text('Volver a subir'), findsNothing);
  });

  testWidgets('muestra "Volver a subir" y el motivo cuando fue rechazado', (
    tester,
  ) async {
    // Arrange
    final document = ProfessionalDocument(
      referenceId: 'doc-1',
      professionalDocumentType: _type(),
      fileKey: 'abc.jpg',
      status: DocumentReviewStatus.rejected,
      rejectionReason: 'Foto ilegible',
      createdAt: DateTime.utc(2026, 8, 27),
    );

    // Act
    await _pump(
      tester,
      statuses: [MyDocumentStatus(documentType: _type(), document: document)],
    );

    // Assert
    expect(find.text('Rechazado'), findsOneWidget);
    expect(find.text('Volver a subir'), findsOneWidget);
    expect(find.text('Foto ilegible'), findsOneWidget);
  });
}
