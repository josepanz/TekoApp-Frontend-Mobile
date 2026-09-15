// Tests de `tool/openapi_codegen/src/dart_model_parser.dart` — el parser por línea + conteo de
// llaves que lee campos de un modelo Dart TAL COMO ESTÁ en el repo (a mano o generado). Cubre las
// formas reales que aparecen en `lib/features/**/models/*.dart`: constructores con parámetros
// nombrados, factories de una expresión y de bloque, getters derivados (una y varias líneas), y
// varias clases en el mismo archivo.
import 'package:flutter_test/flutter_test.dart';

import '../../../tool/openapi_codegen/src/dart_model_parser.dart';

void main() {
  group('parseDartFields', () {
    test('extrae campos requeridos y opcionales de una clase simple', () {
      const source = '''
class BudgetLineItem {
  const BudgetLineItem({
    required this.referenceId,
    required this.quantity,
    this.catalogItemReferenceId,
  });

  final String referenceId;
  final String? catalogItemReferenceId;
  final double quantity;

  factory BudgetLineItem.fromJson(Map<String, dynamic> json) {
    return BudgetLineItem(
      referenceId: json['referenceId'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      catalogItemReferenceId: json['catalogItemReferenceId'] as String?,
    );
  }
}
''';

      final fields = parseDartFields(source, 'BudgetLineItem');

      expect(
        fields,
        containsAll([
          const DartModelField(
            name: 'referenceId',
            declaredType: 'String',
            nullable: false,
          ),
          const DartModelField(
            name: 'catalogItemReferenceId',
            declaredType: 'String',
            nullable: true,
          ),
          const DartModelField(
            name: 'quantity',
            declaredType: 'double',
            nullable: false,
          ),
        ]),
      );
      expect(fields, hasLength(3));
    });

    test('no confunde parámetros del constructor con campos', () {
      // Los parámetros nombrados del constructor viven a profundidad 2 (dentro del `({` que abre
      // la clase Y el paréntesis) — si el parser los contara como campos, "quantity" aparecería
      // duplicado o con el tipo equivocado.
      const source = '''
class Foo {
  const Foo({required this.a, this.b});

  final int a;
  final String? b;
}
''';
      final fields = parseDartFields(source, 'Foo');
      expect(fields, hasLength(2));
      expect(fields.map((f) => f.name), containsAll(['a', 'b']));
    });

    test('ignora getters derivados de una sola línea (=>)', () {
      const source = '''
class BudgetLineItemDraft {
  BudgetLineItemDraft({required this.quantity, required this.unitPrice});

  double quantity;
  double unitPrice;

  double get subtotal => quantity * unitPrice;
}
''';
      final fields = parseDartFields(source, 'BudgetLineItemDraft');
      expect(fields.map((f) => f.name), isNot(contains('subtotal')));
      expect(fields, hasLength(2));
    });

    test('ignora getters derivados con cuerpo de bloque/switch', () {
      const source = '''
class Contract {
  const Contract({required this.status});

  final String status;

  bool get isPendingViewerSignature => switch (status) {
        'DRAFT' => true,
        _ => false,
      };

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(status: json['status'] as String);
  }
}
''';
      final fields = parseDartFields(source, 'Contract');
      expect(fields, hasLength(1));
      expect(fields.single.name, 'status');
    });

    test('reconoce campos mutables sin `final` (estado local de UI)', () {
      const source = '''
class BudgetOptionDraft {
  BudgetOptionDraft({required this.label, this.estimatedHours});

  String label;
  double? estimatedHours;
}
''';
      final fields = parseDartFields(source, 'BudgetOptionDraft');
      expect(
        fields,
        containsAll([
          const DartModelField(
            name: 'label',
            declaredType: 'String',
            nullable: false,
          ),
          const DartModelField(
            name: 'estimatedHours',
            declaredType: 'double',
            nullable: true,
          ),
        ]),
      );
    });

    test('reconoce tipos genéricos (List<T>, Map<String, dynamic>)', () {
      const source = '''
class Rating {
  const Rating({required this.criteria, required this.tags});

  final Map<String, dynamic>? criteria;
  final List<String> tags;
}
''';
      final fields = parseDartFields(source, 'Rating');
      expect(
        fields,
        containsAll([
          const DartModelField(
            name: 'criteria',
            declaredType: 'Map<String, dynamic>',
            nullable: true,
          ),
          const DartModelField(
            name: 'tags',
            declaredType: 'List<String>',
            nullable: false,
          ),
        ]),
      );
    });

    test(
        'distingue clases con nombres solapados (Contract vs ContractContentSnapshot)',
        () {
      const source = '''
class ContractContentSnapshot {
  const ContractContentSnapshot({required this.lineItems});
  final List<String> lineItems;
}

class Contract {
  const Contract({required this.status});
  final String status;
}
''';
      final snapshotFields = parseDartFields(source, 'ContractContentSnapshot');
      expect(snapshotFields.single.name, 'lineItems');

      final contractFields = parseDartFields(source, 'Contract');
      expect(contractFields.single.name, 'status');
    });

    test('tira StateError si la clase no existe en el archivo', () {
      const source = 'class Foo { final int a; }';
      expect(
        () => parseDartFields(source, 'Bar'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('topLevelTypeNamesIn', () {
    test('lista clases y enums declarados a nivel de archivo', () {
      const source = '''
enum BudgetLineItemType { material, labor, other }

class BudgetLineItem {
  const BudgetLineItem();
}

sealed class BudgetFailure implements Exception {
  const BudgetFailure();
}

class BudgetConflictFailure extends BudgetFailure {
  const BudgetConflictFailure();
}
''';
      final names = topLevelTypeNamesIn(source);
      expect(
        names,
        containsAll([
          'BudgetLineItemType',
          'BudgetLineItem',
          'BudgetFailure',
          'BudgetConflictFailure',
        ]),
      );
    });
  });
}
